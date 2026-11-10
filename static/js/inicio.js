const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];

let inventarioPOS = [];
let carritoPOS = [];
let pagosPOS = [{ medio: "efectivo", importe: 0 }];
let cajaPOS = null;
let ventaEnCurso = false;
let solicitudPOS = null;
let ultimoComprobante = "";
let busquedaProductos = 0;
let busquedaInventario = 0;
const formulariosEnCurso = new Set();
const claveSolicitud = `techflow:venta-pendiente:${location.origin}`;
try {
    solicitudPOS = JSON.parse(localStorage.getItem(claveSolicitud) || "null");
    if (solicitudPOS?.payload && Array.isArray(solicitudPOS.carrito)) {
        carritoPOS = solicitudPOS.carrito;
        pagosPOS = solicitudPOS.payload.pagos;
    } else {
        solicitudPOS = null;
    }
} catch (_) {
    solicitudPOS = null;
}

function escapar(value) {
    return String(value ?? "").replace(/[&<>"']/g, (char) => ({
        "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    }[char]));
}

function fechaLocal(value = new Date()) {
    return [value.getFullYear(), String(value.getMonth() + 1).padStart(2, "0"),
        String(value.getDate()).padStart(2, "0")].join("-");
}

function bloquearPOS() {
    $$("#puntoVenta input, #puntoVenta select, #puntoVenta button").forEach((element) => {
        element.disabled = ventaEnCurso || Boolean(solicitudPOS);
    });
    $("#btnConfirmarVenta").disabled = ventaEnCurso || (!solicitudPOS && !cajaPOS);
}


async function api(url, options = {}) {
    const response = await fetch(url, {
        ...options,
        headers: {
            "Content-Type": "application/json",
            ...(options.headers || {}),
        },
    });

    const data = await response.json().catch(() => ({
        error: "Respuesta invalida",
    }));

    if (!response.ok) {
        const error = new Error(data.error?.mensaje || data.error || "No se pudo completar la operacion");
        error.status = response.status;
        throw error;
    }

    if (!data || typeof data !== "object" || (!Object.hasOwn(data, "datos") && !Object.hasOwn(data, "estado") && !Object.hasOwn(data, "id") && !Object.hasOwn(data, "mensaje"))) {
        throw new Error("Respuesta invalida del servidor. Reintenta la misma operacion.");
    }
    return data;
}

function money(value) {
    return "$ " + Number(value || 0).toLocaleString("es-AR", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
    });
}

function number(value) {
    return Number(value || 0);
}

function toast(message) {
    const element = $("#toast");
    element.textContent = message;
    element.classList.add("show");
    setTimeout(() => element.classList.remove("show"), 2600);
}

function table(headers, rows) {
    const body = rows.length
        ? rows
            .map((row) => `
                <tr>
                    ${row.map((cell) => `<td>${cell && typeof cell === "object"
                        ? `<span class="${["ok", "bad", "warn"].includes(cell.clase) ? cell.clase : ""}">${escapar(cell.texto)}</span>`
                        : escapar(cell)}</td>`).join("")}
                </tr>
            `)
            .join("")
        : `
            <tr>
                <td colspan="${headers.length}" class="muted">Sin datos</td>
            </tr>
        `;

    return `
        <table class="table">
            <thead>
                <tr>
                    ${headers.map((header) => `<th>${escapar(header)}</th>`).join("")}
                </tr>
            </thead>
            <tbody>${body}</tbody>
        </table>
    `;
}

$$('.navbtn').forEach((button) => {
    button.onclick = () => cambiarSeccion(button.dataset.tab);
});

function cambiarSeccion(tabId) {
    $$('.navbtn').forEach((button) => {
        button.classList.toggle("active", button.dataset.tab === tabId);
    });

    $$('.tab').forEach((tab) => {
        tab.classList.toggle("active", tab.id === tabId);
    });

    const acciones = {
        resumen: cargarTodo,
        puntoVenta: cargarPuntoVenta,
        productos: cargarProductos,
        inventario: cargarInventario,
        ventas: cargarVentas,
        caja: cargarCaja,
        estadisticas: cargarStats,
    };

    if (acciones[tabId]) {
        acciones[tabId]();
    }
    if (tabId === "resumen") {
        cargarTodo();
    }
}

async function estado() {
    try {
        const data = await api("/api/estado");
        const conectada = data.base_datos === "conectada";
        const element = $("#estado");
        if (element) {
            element.textContent = conectada ? "Operativo" : "BD no disponible";
            element.classList.toggle("status-ok", conectada);
            element.classList.toggle("status-warn", !conectada);
        }
        return conectada;
    } catch (error) {
        const element = $("#estado");
        if (element) element.textContent = "Servidor no disponible";
        return false;
    }
}

async function cargarTodo() {
    const hoy = fechaLocal();
    try {
        const [data, today, cash, sales] = await Promise.all([
            api("/api/estadisticas/resumen"),
            api(`/api/estadisticas/resumen?desde=${hoy}&hasta=${hoy}`),
            api("/api/caja/actual"),
            api(`/api/ventas?desde=${hoy}&hasta=${hoy}&limite=8`),
        ]);
        $("#cards").innerHTML = [
            ["Ventas (ultimos 30 dias)", data.datos.ventas],
            ["Facturacion (ultimos 30 dias)", money(data.datos.total)],
            ["Promedio", money(data.datos.promedio)],
            ["Estado", "Operativo"],
        ].map(([label, value], index) => `
            <div class="card">
                <div class="label">${escapar(label)}</div>
                <div class="value" ${index === 3 ? 'id="estado"' : ""}>${escapar(value)}</div>
            </div>`).join("");
        $("#ventasHoy").textContent = today.datos.ventas;
        $("#totalHoy").textContent = money(today.datos.total);
        $("#productosVendidos").textContent = today.datos.unidades;
        $("#saldoCaja").textContent = money(cash.datos?.saldo_actual);
        $("#estadoCaja").textContent = cash.datos ? `Caja #${cash.datos.id} abierta` : "Sin caja abierta";
        $("#ultimasVentas").innerHTML = sales.datos.length ? table(
            ["ID", "Fecha", "Total", "Pago", "Estado"],
            sales.datos.map((item) => [item.id, new Date(item.fecha_hora).toLocaleString("es-AR"),
                money(item.total), item.medio_pago, item.estado])
        ) : '<p class="mensaje-vacio">Aun no hay ventas registradas hoy.</p>';
    } catch (error) {
        ["ventasHoy", "totalHoy", "productosVendidos", "saldoCaja"].forEach((id) => {
            $(`#${id}`).textContent = "—";
        });
        $("#estadoCaja").textContent = "Datos no disponibles";
        $("#ultimasVentas").textContent = "No se pudieron cargar las ventas.";
        $("#cards").innerHTML = '<div class="card"><div class="label">Estado</div><div class="value" id="estado">Datos no disponibles</div></div>';
        toast(error.message);
    }
    await estado();
}

async function cargarProductos() {
    const version = ++busquedaProductos;
    try {
        const query = encodeURIComponent($("#busqueda")?.value || "");
        const inactive = $("#inactivos")?.checked
            ? "&incluir_inactivos=true"
            : "";
        const data = await api(`/api/productos?q=${query}${inactive}`);

        if (version !== busquedaProductos) return;
        $("#tablaProductos").innerHTML = table(
            ["Producto", "Categoria", "Precio", "Estado"],
            data.datos.map((item) => [
                item.nombre,
                item.categoria,
                money(item.precio),
                { texto: item.activo ? "Activo" : "Inactivo", clase: item.activo ? "ok" : "bad" },
            ])
        );
    } catch (error) {
        toast(error.message);
    }
}

function mostrarProducto() {
    const form = $("#formProducto");
    form.classList.remove("hidden");
    form.innerHTML = `
        <h3>Nuevo producto</h3>
        <div class="formgrid">
            <label>
                Nombre
                <input class="field" id="pn">
            </label>
            <label>
                Precio
                <input class="field" id="pp" type="number" min="0.01" step="0.01">
            </label>
            <label>
                Categoria
                <select id="pc" class="field"></select>
            </label>
            <label>
                Descripcion
                <input class="field" id="pd">
            </label>
        </div>
        <div class="formactions">
            <button class="primary" onclick="guardarProducto()">Guardar</button>
            <button onclick="$(\'#formProducto\').classList.add(\'hidden\')">Cancelar</button>
        </div>
    `;

    api("/api/categorias")
        .then((data) => {
            $("#pc").innerHTML = data.datos
                .map((item) => `<option value="${escapar(item.id)}">${escapar(item.nombre)}</option>`)
                .join("");
        })
        .catch((error) => toast(error.message));
}

async function guardarProducto() {
    if (formulariosEnCurso.has("guardarProducto")) return;
    formulariosEnCurso.add("guardarProducto");
    try {
        await api("/api/productos", {
            method: "POST",
            body: JSON.stringify({
                nombre: $("#pn").value,
                precio: $("#pp").value,
                categoria_id: $("#pc").value,
                descripcion: $("#pd").value,
            }),
        });

        toast("Producto guardado");
        $("#formProducto").classList.add("hidden");
        cargarProductos();
    } catch (error) {
        toast(error.message);
    } finally {
        formulariosEnCurso.delete("guardarProducto");
    }
}

async function cargarInventario() {
    const version = ++busquedaInventario;
    try {
        const query = encodeURIComponent($("#busqStock")?.value || "");
        const bajo = $("#soloBajo")?.checked ? "&solo_bajo=true" : "";
        const data = await api(`/api/inventario?q=${query}${bajo}`);

        if (version !== busquedaInventario) return;
        $("#tablaInventario").innerHTML = table(
            ["Codigo", "Producto", "Talle", "Color", "Stock", "Minimo"],
            data.datos.map((item) => [
                item.codigo,
                item.producto,
                item.talle,
                item.color,
                item.stock_actual <= item.stock_minimo
                    ? { texto: item.stock_actual, clase: "warn" }
                    : item.stock_actual,
                item.stock_minimo,
            ])
        );
    } catch (error) {
        toast(error.message);
    }
}

function mostrarMovimiento() {
    const form = $("#formMovimiento");
    form.classList.remove("hidden");
    form.innerHTML = `
        <h3>Movimiento de stock</h3>
        <div class="formgrid">
            <label>
                Variante ID
                <input class="field" id="mi" type="number" min="1" step="1" list="variantesStock"><datalist id="variantesStock"></datalist>
            </label>
            <label>
                Tipo
                <select class="field" id="mt">
                    <option value="ingresos">Ingreso</option>
                    <option value="ajustes">Ajuste (stock final)</option>
                </select>
            </label>
            <label>
                Cantidad
                <input class="field" id="mc" type="number" min="0">
            </label>
            <label>
                Motivo
                <input class="field" id="mm">
            </label>
        </div>
        <button class="primary" onclick="guardarMovimiento()">Registrar</button>
    `;
    api("/api/inventario").then(({datos}) => {
        $("#variantesStock").innerHTML = datos.map((item) => `<option value="${escapar(item.id)}">${escapar(item.codigo)} · ${escapar(item.producto)}</option>`).join("");
    }).catch((error) => toast(error.message));
}

async function guardarMovimiento() {
    if (formulariosEnCurso.has("guardarMovimiento")) return;
    formulariosEnCurso.add("guardarMovimiento");
    try {
        const tipo = $("#mt").value;
        await api(`/api/inventario/${tipo}`, {
            method: "POST",
            body: JSON.stringify({
                variante_id: $("#mi").value,
                cantidad: $("#mc").value,
                motivo: $("#mm").value,
            }),
        });

        toast("Movimiento registrado");
        $("#formMovimiento").classList.add("hidden");
        cargarInventario();
    } catch (error) {
        toast(error.message);
    } finally {
        formulariosEnCurso.delete("guardarMovimiento");
    }
}

async function cargarVentas() {
    try {
        const data = await api("/api/ventas");
        $("#tablaVentas").innerHTML = table(
            ["ID", "Fecha", "Total", "Pago", "Estado"],
            data.datos.map((item) => [
                item.id,
                new Date(item.fecha_hora).toLocaleString("es-AR"),
                money(item.total),
                item.medio_pago,
                item.estado,
            ])
        );
    } catch (error) {
        toast(error.message);
    }
}

async function cargarPuntoVenta() {
    try {
        const [inventory, cash] = await Promise.all([
            api("/api/inventario"),
            api("/api/caja/actual"),
        ]);

        inventarioPOS = inventory.datos;
        if (!solicitudPOS) {
            carritoPOS.forEach((linea) => {
                const actual = inventarioPOS.find((item) => number(item.id) === linea.variante_id);
                linea.stock = actual ? number(actual.stock_actual) : 0;
                if (actual) linea.precio = number(actual.precio);
            });
        }
        cajaPOS = cash.datos;
        renderCajaPOS();

        if (!cajaPOS && !solicitudPOS) {
            $("#posProducto").innerHTML = "<option value=\"\">Abrir una caja primero</option>";
            $("#posCarrito").innerHTML = `
                <div class="empty-state">
                    No hay una caja abierta. Abri la caja antes de registrar cobros.
                </div>
            `;
            bloquearPOS();
            $("#btnConfirmarVenta").disabled = true;
            return;
        }

        $("#btnConfirmarVenta").disabled = false;
        renderProductosPOS();

        if (!pagosPOS.length) {
            pagosPOS = [{ medio: "efectivo", importe: 0 }];
        }

        if (solicitudPOS) $("#posEfectivoRecibido").value = solicitudPOS.payload.efectivo_recibido;
        renderPos();
        bloquearPOS();
    } catch (error) {
        toast(error.message);
    }
}

function renderCajaPOS() {
    $("#posCaja").innerHTML = cajaPOS
        ? `<span class="open-dot"></span> Caja #${escapar(cajaPOS.id)} abierta`
        : '<span class="closed-dot"></span> Caja cerrada';
}

function filtrarProductosPOS() {
    renderProductosPOS();
}


function renderProductosPOS() {
    const search = ($("#posBusqueda")?.value || "")
        .trim()
        .toLowerCase();

    const disponibles = inventarioPOS.filter((item) => {
        if (number(item.stock_actual) <= 0) return false;

        const texto = [
            item.codigo,
            item.producto,
            item.talle,
            item.color
        ].join(" ").toLowerCase();

        return texto.includes(search);
    });

    // Conservar el selector que utiliza el sistema actual
    $("#posProducto").innerHTML = disponibles.length
        ? disponibles.map(item => `
            <option value="${escapar(item.id)}">
                ${escapar(item.codigo)} - ${escapar(item.producto)}
            </option>
        `).join("")
        : '<option value="">Sin productos disponibles</option>';

    $("#posCantidadProductos").textContent =
        `${disponibles.length} productos`;

    const catalogo = $("#posCatalogo");

    if (!disponibles.length) {
        catalogo.innerHTML = `
            <div class="empty-state">
                No hay productos disponibles.
            </div>
        `;
        return;
    }

    catalogo.innerHTML = disponibles.map(item => `
        <article class="pos-product-card">

            <div class="pos-product-art">
                <span>${escapar(
                    String(item.producto || "P").charAt(0).toUpperCase()
                )}</span>
            </div>

            <div class="pos-product-info">

                <div class="pos-product-name">
                    ${escapar(item.producto)}
                </div>

                <div class="pos-product-detail">
                    ${escapar(item.codigo)} ·
                    ${escapar(item.talle)}/${escapar(item.color)}
                </div>

                <div class="pos-product-stock">
                    Stock disponible: ${number(item.stock_actual)}
                </div>

                <div class="pos-product-price">
                    ${money(item.precio)}
                </div>

                <button
                    class="pos-add-button"
                    onclick="agregarProductoCatalogo(${Number(item.id)})"
                    ${!cajaPOS || solicitudPOS || ventaEnCurso ? "disabled" : ""}
                >
                    + Agregar
                </button>

            </div>
        </article>
    `).join("");
}



function agregarProductoCatalogo(id) {
    if (!cajaPOS || solicitudPOS || ventaEnCurso) return;

    $("#posProducto").value = String(id);
    $("#posCantidad").value = 1;

    agregarAlCarrito();
}



function agregarAlCarrito() {
    if (ventaEnCurso || solicitudPOS) return;
    ultimoComprobante = "";
    const variantId = number($("#posProducto").value);
    const quantity = number($("#posCantidad").value);
    const item = inventarioPOS.find((row) => number(row.id) === variantId);

    if (!item) {
        toast("Selecciona una variante disponible");
        return;
    }

    if (!Number.isSafeInteger(quantity) || quantity <= 0) {
        toast("La cantidad debe ser un entero positivo");
        return;
    }

    const existing = carritoPOS.find(
        (row) => row.variante_id === variantId
    );
    const nextQuantity = (existing?.cantidad || 0) + quantity;

    if (nextQuantity > number(item.stock_actual)) {
        toast("La cantidad supera el stock disponible");
        return;
    }

    if (existing) {
        existing.cantidad = nextQuantity;
    } else {
        carritoPOS.push({
            variante_id: variantId,
            cantidad: quantity,
            nombre: item.producto,
            detalle: `${item.codigo} · ${item.talle}/${item.color}`,
            precio: number(item.precio),
            stock: number(item.stock_actual),
        });
    }

    $("#posCantidad").value = 1;
    renderPos();
}

function cambiarCantidadCarrito(index, value) {
    if (ventaEnCurso || solicitudPOS) return;
    ultimoComprobante = "";
    const quantity = number(value);
    const item = carritoPOS[index];

    if (!item) {
        return;
    }

    if (!Number.isSafeInteger(quantity) || quantity <= 0) {
        toast("La cantidad debe ser un entero positivo");
        renderPos();
        return;
    }

    if (quantity > item.stock) {
        toast("La cantidad supera el stock disponible");
        renderPos();
        return;
    }

    item.cantidad = quantity;
    renderPos();
}

function eliminarDelCarrito(index) {
    if (ventaEnCurso || solicitudPOS) return;
    ultimoComprobante = "";
    carritoPOS.splice(index, 1);
    renderPos();
}

function vaciarCarrito() {
    if (ventaEnCurso || solicitudPOS) return;
    ultimoComprobante = "";
    carritoPOS = [];
    pagosPOS = [{ medio: "efectivo", importe: 0 }];
    $("#posEfectivoRecibido").value = "";
    $("#posResultado").innerHTML = "";
    renderPos();
}

function totalCarrito() {
    return carritoPOS.reduce(
        (total, item) => total + Math.round(item.precio * 100) * item.cantidad,
        0
    ) / 100;
}

function agregarPago() {
    if (ventaEnCurso || solicitudPOS) return;
    ultimoComprobante = "";
    pagosPOS.push({ medio: "transferencia", importe: 0 });
    renderPos();
}

function eliminarPago(index) {
    if (ventaEnCurso || solicitudPOS) return;
    ultimoComprobante = "";
    if (pagosPOS.length === 1) {
        toast("Debe quedar al menos un medio de pago");
        return;
    }

    pagosPOS.splice(index, 1);
    renderPos();
}

function actualizarPago(index, field, value) {
    if (ventaEnCurso || solicitudPOS) return;
    ultimoComprobante = "";
    pagosPOS[index][field] = field === "importe"
        ? number(value)
        : value;
    renderPos(false);
}

function completarPago(index) {
    if (ventaEnCurso || solicitudPOS) return;
    ultimoComprobante = "";
    const total = totalCarrito();
    const otros = pagosPOS.reduce(
        (sum, payment, position) => {
            return position === index
                ? sum
                : sum + number(payment.importe);
        },
        0
    );

    pagosPOS[index].importe = Math.max(0, Math.round((total - otros) * 100) / 100);
    renderPos();
}

function renderPos(actualizarFilas = true) {
    const total = totalCarrito();
    const pagosTotal = pagosPOS.reduce(
        (sum, payment) => sum + number(payment.importe),
        0
    );
    const diferencia = total - pagosTotal;
    const efectivo = pagosPOS.reduce(
        (sum, payment) => {
            return payment.medio === "efectivo"
                ? sum + number(payment.importe)
                : sum;
        },
        0
    );
    const recibido = number($("#posEfectivoRecibido")?.value);
    const cambio = Math.max(0, Math.round((recibido - efectivo) * 100) / 100);

    $("#posCarrito").innerHTML = carritoPOS.length
        ? `
            <div class="cart-head">
                <span>Carrito</span>
                <strong>${carritoPOS.length} producto(s)</strong>
            </div>
            ${carritoPOS.map((item, index) => `
                <div class="cart-row">
                    <div class="cart-product">
                        <strong>${escapar(item.nombre)}</strong>
                        <span>${escapar(item.detalle)}</span>
                    </div>
                    <input
                        class="qty"
                        type="number"
                        min="1"
                        max="${item.stock}"
                        value="${item.cantidad}"
                        onchange="cambiarCantidadCarrito(${index}, this.value)"
                    >
                    <strong>${money(item.precio * item.cantidad)}</strong>
                    <button
                        class="iconbtn"
                        onclick="eliminarDelCarrito(${index})"
                    >
                        Quitar
                    </button>
                </div>
            `).join("")}
        `
        : '<div class="empty-cart">El carrito esta vacio.</div>';

    $("#posResumen").innerHTML = `
        <div class="summary-line">
            <span>Subtotal</span>
            <strong>${money(total)}</strong>
        </div>
        <div class="summary-total">
            <span>Total a cobrar</span>
            <strong>${money(total)}</strong>
        </div>
    `;

    if (actualizarFilas) $("#posPagos").innerHTML = pagosPOS.map((payment, index) => `
        <div class="payment-row">
            <select
                class="field"
                onchange="actualizarPago(${index}, 'medio', this.value)"
            >
                <option value="efectivo" ${payment.medio === "efectivo" ? "selected" : ""}>
                    Efectivo
                </option>
                <option value="transferencia" ${payment.medio === "transferencia" ? "selected" : ""}>
                    Transferencia
                </option>
                <option value="tarjeta" ${payment.medio === "tarjeta" ? "selected" : ""}>
                    Tarjeta
                </option>
            </select>
            <input
                class="field"
                type="number"
                min="0"
                step="0.01"
                value="${payment.importe || ""}"
                oninput="actualizarPago(${index}, 'importe', this.value)"
            >
            <button class="linkbtn" onclick="completarPago(${index})">
                Completar
            </button>
            ${pagosPOS.length > 1 ? `
                <button class="iconbtn" onclick="eliminarPago(${index})">
                    Quitar
                </button>
            ` : ""}
        </div>
    `).join("");

    $("#posEfectivoBox").classList.toggle("hidden", efectivo <= 0);
    $("#posCambio").textContent = efectivo > 0
        ? `Cambio: ${money(cambio)}`
        : "";

    const summary = $("#posResultado");

    if (
        carritoPOS.length &&
        Math.round(diferencia * 100) === 0 &&
        (efectivo === 0 || recibido >= efectivo)
    ) {
        summary.innerHTML = '<div class="ready">Cobro listo para confirmar.</div>';
    } else if (carritoPOS.length) {
        summary.innerHTML = `
            <div class="pending">
                ${Math.round(diferencia * 100) > 0 ? `Falta cobrar ${money(diferencia)}.`
                    : Math.round(diferencia * 100) < 0 ? `Los pagos exceden el total en ${money(-diferencia)}.`
                    : `Falta recibir ${money(Math.max(0, efectivo - recibido))} en efectivo.`}
            </div>
        `;
    } else {
        summary.innerHTML = ultimoComprobante;
    }
}

async function confirmarCobro() {
    if (ventaEnCurso) return;
    if (!solicitudPOS) {
        if (!cajaPOS || !carritoPOS.length) {
            toast("Abri una caja y agrega al menos un producto");
            return;
        }
        if (carritoPOS.some((item) => !Number.isSafeInteger(item.cantidad) || item.cantidad <= 0 || item.cantidad > item.stock)) {
            toast("Revisa las cantidades y el stock del carrito.");
            return;
        }
        if (pagosPOS.some((payment) => !Number.isFinite(number(payment.importe)) || number(payment.importe) < 0)) {
            toast("Los importes de pago deben ser numeros positivos");
            return;
        }
        const pagos = pagosPOS.filter((payment) => number(payment.importe) > 0).map((payment) => ({
            medio: payment.medio, importe: number(payment.importe).toFixed(2),
        }));
        const suma = pagos.reduce((sum, payment) => sum + Math.round(number(payment.importe) * 100), 0);
        const efectivo = pagos.filter((payment) => payment.medio === "efectivo")
            .reduce((sum, payment) => sum + Math.round(number(payment.importe) * 100), 0);
        const recibido = number($("#posEfectivoRecibido").value);
        if (!Number.isFinite(recibido) || recibido < 0 || suma !== Math.round(totalCarrito() * 100) || !pagos.length) {
            toast(`Los pagos deben sumar exactamente ${money(totalCarrito())}`);
            return;
        }
        if (Math.round(recibido * 100) < efectivo) {
            toast("El efectivo recibido no alcanza");
            return;
        }
        const pending = {payload: {
            solicitud_id: crypto.randomUUID(), caja_id: cajaPOS.id,
            items: carritoPOS.map((item) => ({variante_id: item.variante_id, cantidad: item.cantidad})),
            pagos, efectivo_recibido: recibido.toFixed(2),
        }, carrito: carritoPOS};
        try {
            localStorage.setItem(claveSolicitud, JSON.stringify(pending));
            solicitudPOS = pending;
        } catch (_) {
            toast("No se pudo guardar el cobro pendiente en este navegador.");
            return;
        }
    }
    ventaEnCurso = true;
    bloquearPOS();
    const button = $("#btnConfirmarVenta");
    button.textContent = "Guardando...";
    try {
        const response = await api("/api/ventas", {method: "POST", body: JSON.stringify(solicitudPOS.payload)});
        const sale = response.datos;
        if (!sale?.id || sale.total == null || sale.cambio == null) throw new Error("Respuesta de cobro incompleta");
        // Si se pierde la respuesta, la solicitud persistida se reenvia sin cambios.
        localStorage.removeItem(claveSolicitud);
        solicitudPOS = null;
        ultimoComprobante = `<div class="sale-success"><strong>Venta #${escapar(sale.id)} confirmada</strong>
            <span>Total: ${escapar(money(sale.total))}</span><span>Cambio: ${escapar(money(sale.cambio))}</span></div>`;
        carritoPOS = [];
        pagosPOS = [{medio: "efectivo", importe: 0}];
        $("#posEfectivoRecibido").value = "";
        renderPos();
        toast(`Venta #${sale.id} registrada`);
        await Promise.all([cargarPuntoVenta(), cargarVentas(), cargarInventario(), cargarTodo()]);
    } catch (error) {
        if ([400, 404, 409, 413, 422].includes(error.status)) {
            localStorage.removeItem(claveSolicitud);
            solicitudPOS = null;
            await cargarPuntoVenta();
            toast(error.message);
        } else {
            toast("No se pudo confirmar el resultado. Pulsa Confirmar cobro para reintentar la misma venta.");
        }
    } finally {
        ventaEnCurso = false;
        button.textContent = "Confirmar cobro";
        bloquearPOS();
    }
}

async function cargarCaja() {
    try {
        const data = await api("/api/caja/actual");
        const panel = $("#panelCaja");

        if (!data.datos) {
            panel.innerHTML = `
                <h3>No hay caja abierta</h3>
                <div class="formgrid">
                    <label>
                        Saldo inicial
                        <input
                            class="field"
                            id="si"
                            type="number"
                            min="0"
                            step="0.01"
                            value="0"
                        >
                    </label>
                </div>
                <button class="primary" onclick="abrirCaja()">Abrir caja</button>
            `;
            return;
        }

        panel.innerHTML = `
            <h3>Caja #${data.datos.id}</h3>
            <p>
                Abierta desde
                ${new Date(data.datos.fecha_apertura).toLocaleString("es-AR")}
            </p>
            <div class="formgrid">
                <label>
                    Efectivo contado al cierre
                    <input
                        class="field"
                        id="cc"
                        type="number"
                        min="0"
                        step="0.01"
                    >
                </label>
            </div>
            <button
                class="primary"
                onclick="cerrarCaja(${data.datos.id})"
            >
                Cerrar caja
            </button>
        `;
    } catch (error) {
        toast(error.message);
    }
}

async function abrirCaja() {
    if (formulariosEnCurso.has("abrirCaja")) return;
    formulariosEnCurso.add("abrirCaja");
    try {
        await api("/api/caja/aperturas", {
            method: "POST",
            body: JSON.stringify({
                saldo_inicial: $("#si").value,
            }),
        });

        toast("Caja abierta");
        await cargarCaja();
        await cargarPuntoVenta();
    } catch (error) {
        toast(error.message);
    } finally {
        formulariosEnCurso.delete("abrirCaja");
    }
}

async function cerrarCaja(id) {
    if (formulariosEnCurso.has("cerrarCaja")) return;
    formulariosEnCurso.add("cerrarCaja");
    try {
        const data = await api(`/api/caja/${id}/cierres`, {
            method: "POST",
            body: JSON.stringify({
                efectivo_contado: $("#cc").value,
            }),
        });

        toast(`Caja cerrada · diferencia ${money(data.datos.diferencia)}`);
        await cargarCaja();
        await cargarPuntoVenta();
    } catch (error) {
        toast(error.message);
    } finally {
        formulariosEnCurso.delete("cerrarCaja");
    }
}

async function cargarStats() {
    try {
        const desde = $("#desde").value;
        const hasta = $("#hasta").value;
        const params = new URLSearchParams();

        if (desde) {
            params.set("desde", desde);
        }

        if (hasta) {
            params.set("hasta", hasta);
        }

        const query = params.toString() ? `?${params}` : "";
        const data = await api(`/api/estadisticas/resumen${query}`);

        $("#statsCards").innerHTML = [
            ["Ventas", data.datos.ventas],
            ["Facturacion", money(data.datos.total)],
            ["Ticket promedio", money(data.datos.promedio)],
        ]
            .map(([label, value]) => `
                <div class="card">
                    <div class="label">${label}</div>
                    <div class="value">${value}</div>
                </div>
            `)
            .join("");

        const ranking = await api(`/api/estadisticas/productos${query}`);
        $("#ranking").innerHTML = `
            <h3>Productos mas vendidos</h3>
            ${table(
                ["Producto", "Unidades", "Facturacion"],
                ranking.datos.map((item) => [
                    item.producto,
                    item.unidades,
                    money(item.facturacion),
                ])
            )}
        `;
    } catch (error) {
        toast(error.message);
    }
}

(function iniciar() {
    const today = new Date();
    const start = new Date(today);
    start.setDate(today.getDate() - 29);

    $("#desde").value = start.toISOString().slice(0, 10);
    $("#hasta").value = today.toISOString().slice(0, 10);

    estado();
    cargarTodo();

    // Actualizar el panel cada 30 segundos
    setInterval(() => {
        if ($("#resumen").classList.contains("active")) {
            cargarTodo();
        }
    }, 30000);

})();
