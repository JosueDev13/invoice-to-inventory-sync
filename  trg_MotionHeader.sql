CREATE TRIGGER trg_MotionHeader ON dbo.facturas
AFTER
INSERT,
    UPDATE,
    DELETE AS BEGIN
    /******************************************************************************************
     Nombre del Trigger : trg_MovementDetail
     Tabla              : dbo.facturas
     Acciones usadas    : AFTER INSERT, UPDATE
     Descripción        : Genera o actualiza movimientos (encabezado) en PHData2.dbo.datamov (DDBB de Recan) 
     cuando se inserta o actualiza un encabezado de factura
     del cliente '178488-1' (Código de proveedor en la DDBB de Recan y mismo
     código usado en Equipos).
     
     Autor              : Josué Crespín
     Fecha de creación  : 2025-08-16
     Notas              : Se usa MERGE para insertar o actualizar registros.
     ******************************************************************************************/
SET NOCOUNT ON;
/* Aqui se inserta o se actualiza*/
/*Damo inicio a nuestro trigger mediante un if para validar si existe o no */
IF EXISTS (
    SELECT 1
    FROM inserted
) BEGIN;
WITH source_cte AS (
    SELECT i.numero,
        MAX(f.fecha) AS fecha,
        -- Cambio, se inserta la fecha de la factura para el movimiento
        MAX(f.cliente) AS codproveedor,
        MAX(f.tipofact) AS tipofact,
        MAX(f.valortot) AS total,
        /*  Aquí comienza la lógica de validación,, dentro de este se valida si el comprobantes es credito fiscal, una anulacion o 
         una notda de credito, esto basado en campo de la tabla conceptos, y la combinacion de campos de anulacion, asi se concluye la 
         asignacion de si es entrada o salida de inventario para la DB uno*/
        CASE
            WHEN MAX(
                CASE
                    WHEN c.EsDevoFa = 1
                    OR f.anulado = 1
                    OR f.anulado2 = 1 THEN 1
                    ELSE 0
                END
            ) = 1 THEN 'SL-1'
            ELSE 'CI-1'
        END AS concepto,
        CASE
            WHEN MAX(
                CASE
                    WHEN c.EsDevoFa = 1
                    OR f.anulado = 1
                    OR f.anulado2 = 1 THEN 1
                    ELSE 0
                END
            ) = 1 THEN 'S'
            ELSE 'E'
        END AS tipo
    FROM inserted i
        INNER JOIN dbo.facturas f ON f.numero = i.numero
        AND f.tipofact = i.tipofact
        INNER JOIN dbo.conceptos c ON c.concepto = f.tipofact
        /* Validación para determinar si el trigger se ejecuta, este busca en la tabla de facturas a un cliente en especifico 
         para poder realizar su accion si este no se cumple ignora */
    WHERE f.cliente = '178488-1'
    GROUP BY i.numero,
        i.tipofact
) MERGE PHData2.dbo.Datamov AS target USING source_cte AS source ON target.numero = source.tipofact + source.numero --Ahora he concatenado para crear un correlativo unico
AND target.concepto = source.concepto
WHEN MATCHED THEN
UPDATE
SET numero = source.tipofact + source.numero,
    tipo = source.tipo,
    fecha = source.fecha,
    FechaDoc = source.fecha,
    codproveedor = source.codproveedor,
    comentarios = 'MOVIMIENTO GENERADO POR LA FACTURA ' + source.tipofact + ' ' + source.numero,
    bodega = 1,
    generado = 0,
    nom_resp = '',
    Suma = 0,
    TieneReparo = 0,
    Reparo = '',
    Estatus = 1,
    Trasportista = '',
    total = source.total,
    usrcreo = 'Norma',
    fecCreo = source.fecha,
    ConceptoProv = source.tipofact,
    comprobProv = source.numero,
    EsRequisicion = 0,
    numIM5 = '',
    idpo = '',
    cierraPO = 0
    WHEN NOT MATCHED THEN
INSERT (
        concepto,
        numero,
        tipo,
        fecha,
        FechaDoc,
        codproveedor,
        comentarios,
        bodega,
        generado,
        nom_resp,
        Suma,
        TieneReparo,
        Reparo,
        Estatus,
        Trasportista,
        total,
        usrcreo,
        fecCreo,
        ConceptoProv,
        comprobProv,
        EsRequisicion,
        numIM5,
        idpo,
        cierraPO
    )
VALUES (
        source.concepto,
        source.tipofact + source.numero,
        source.tipo,
        source.fecha,
        source.fecha,
        source.codproveedor,
        'MOVIMIENTO GENERADO POR LA FACTURA ' + source.tipofact + ' ' + source.numero,
        1,
        0,
        '',
        0,
        0,
        '',
        1,
        '',
        source.total,
        'Norma',
        source.fecha,
        source.tipofact,
        source.numero,
        0,
        '',
        '',
        0
    );
END
/* Aquí un delete CRUDO jajajaja */
IF EXISTS (
    SELECT 1
    FROM deleted
)
AND NOT EXISTS (
    SELECT 1
    FROM inserted
) BEGIN DELETE target
FROM PHData2.dbo.Datamov AS target
    INNER JOIN deleted d ON target.numero = d.tipofact + d.numero
    AND target.concepto IN ('CI-1', 'SL-1')
WHERE d.cliente = '178488-1';
END
END;