CREATE TRIGGER [dbo].[trg_MovementDetail] ON [dbo].[detafac]
AFTER
INSERT,
    UPDATE AS BEGIN
    /******************************************************************************************
     Nombre del Trigger : trg_MovementDetail
     Tabla              : dbo.detafac
     Acciones usadas    : AFTER INSERT, UPDATE
     Descripción        : Genera o actualiza movimientos en PHData2.dbo.movimien (DDBB de Recan) 
     cuando se inserta o actualiza un detalle de factura
     del cliente '178488-1' (Código de proveedor en la DDBB de Recan y mismo
     código usado en Equipos).
     
     Autor              : Josué Crespín
     Fecha de creación  : 2025-08-16
     Notas              : Se usa MERGE para insertar o actualizar registros.
     ******************************************************************************************/
SET NOCOUNT ON;
MERGE PHData2.dbo.movimien AS target USING (
    SELECT CASE
            WHEN c.EsDevoFa = 1
            OR f.anulado = 1
            OR f.anulado2 = 1 THEN 'SL-1'
            ELSE 'CI-1'
        END AS concepto,
        CASE
            WHEN c.EsDevoFa = 1
            OR f.anulado = 1
            OR f.anulado2 = 1 THEN 'S'
            ELSE 'E'
        END AS tipo,
        i.numero,
        i.tipofact,
        i.idarticulo,
        i.cantidad,
        i.cod_unidad,
        i.precio,
        i.factor,
        f.fecha,
        f.cliente
    FROM inserted i
        INNER JOIN dbo.facturas f ON f.numero = i.numero
        AND f.tipofact = i.tipofact
        INNER JOIN dbo.conceptos c ON c.concepto = i.tipofact
    WHERE f.cliente = '178488-1'
) AS source ON target.numero = source.tipofact + source.numero
AND target.idarticulo = source.idarticulo
AND target.tipo = source.tipo
AND target.concepto = source.concepto
AND target.proveedor = source.cliente
WHEN MATCHED THEN
UPDATE
SET cantidad = source.cantidad,
    costo_compra = source.precio,
    costo_prom = source.precio,
    factor = source.factor,
    fecha = source.fecha,
    proveedor = source.cliente,
    TotalCosto2 = source.cantidad * source.precio
    WHEN NOT MATCHED THEN
INSERT (
        concepto,
        tipo,
        numero,
        fecha,
        idarticulo,
        cantidad,
        cod_unidad,
        costo_compra,
        costo_prom,
        factor,
        bodega,
        EnTransito,
        TotalCosto2,
        idgrupo,
        idsubgrupo,
        proveedor,
        usrcreo,
        fecCreo,
        semigro,
        costoPEPS,
        SaldoPEPS,
        CodUnidadVenta,
        CantMov,
        EntPO,
        SalPO,
        im5,
        precio,
        ventas,
        anulado,
        Poliza,
        PO,
        SeAgregoLote,
        Nlote,
        pideLote,
        SeAgregoSerie,
        pideSerie,
        destino,
        Despacho,
        Recibio
    )
VALUES (
        source.concepto,
        source.tipo,
        source.tipofact + source.numero,
        source.fecha,
        source.idarticulo,
        source.cantidad,
        source.cod_unidad,
        source.precio,
        source.precio,
        source.factor,
        1,
        0,
        source.cantidad * source.precio,
        0,
        0,
        source.cliente,
        'Norma',
        source.fecha,
        1,
        0,
        0,
        source.cod_unidad,
        source.cantidad,
        source.cantidad,
        source.cantidad,
        '',
        source.precio,
        0,
        0,
        '',
        '',
        0,
        '',
        0,
        0,
        0,
        0,
        0,
        0
    );
END