# invoice-to-inventory-sync

Automatización de movimientos de inventario en BBDD "B" a partir del registro de facturas (encabezado y detalle) en BBDD "A".

#Definición

Trigger para la sincronización automática de transacciones entre la Base de Datos A (Facturación) y la Base de Datos B (Inventario).
Al registrar una factura en la BD "A", se activan los triggers de encabezado y detalle para generar automáticamente los movimientos de stock correspondientes en la BD "B".

#Adicional

Este se ha combinado con un Stored Procedure el cual se ejecuta mediante una tarea programada para actualizar la existencia de la DB "A"
