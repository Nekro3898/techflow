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
                    ${row.map((cell) => `<td>${cell && typeof cell === "object" && cell.editarProducto
                        ? `<button type="button" onclick="modificarProducto(${Number(cell.editarProducto)})">Modificar</button>`
                        : cell && typeof cell === "object" && cell.imagenProducto
                        ? `<button type="button" onclick="cargarImagenExistente(${Number(cell.imagenProducto)})">Cargar imagen</button>`
                        : cell && typeof cell === "object"
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

const paginasTablas = {};
function tablaPaginada(selector, headers, rows, filtro = "") {
    const anterior = paginasTablas[selector];
    paginasTablas[selector] = {
        headers, rows, filtro,
        pagina: anterior?.filtro === filtro ? anterior.pagina : 1,
    };
    mostrarPaginaTabla(selector, paginasTablas[selector].pagina);
}

function mostrarPaginaTabla(selector, pagina) {
    const estado = paginasTablas[selector];
    const total = estado.rows.length;
    const paginas = Math.max(1, Math.ceil(total / 20));
    estado.pagina = Math.max(1, Math.min(pagina, paginas));
    const inicio = (estado.pagina - 1) * 20;
    const panel = $(selector);
    panel.innerHTML = table(estado.headers, estado.rows.slice(inicio, inicio + 20)) + `
        <nav class="paginacion-tabla" aria-label="Paginación de ${selector === '#tablaVentas' ? 'ventas' : 'inventario'}">
            <span role="status">${total ? inicio + 1 : 0}–${Math.min(inicio + 20, total)} de ${total} registros · Página ${estado.pagina} de ${paginas}</span>
            <div>
                <button type="button" data-paso="-1" ${estado.pagina === 1 ? 'disabled' : ''}>Anterior</button>
                <button type="button" data-paso="1" ${estado.pagina === paginas ? 'disabled' : ''}>Siguiente</button>
            </div>
        </nav>`;
    panel.querySelectorAll('[data-paso]').forEach((button) => {
        button.onclick = () => {
            const paso = Number(button.dataset.paso);
            mostrarPaginaTabla(selector, estado.pagina + paso);
            panel.scrollIntoView({ block: 'start' });
            const controles = panel.querySelectorAll('[data-paso]');
            const preferido = panel.querySelector(`[data-paso="${paso}"]`);
            (preferido.disabled ? [...controles].find((item) => !item.disabled) : preferido)?.focus({ preventScroll: true });
        };
    });
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
        const [today, cash, sales] = await Promise.all([
            api(`/api/estadisticas/resumen?desde=${hoy}&hasta=${hoy}`),
            api("/api/caja/actual"),
            api(`/api/ventas?desde=${hoy}&hasta=${hoy}&limite=8`),
        ]);
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
            ["Producto", "Categoria", "Precio", "Estado", "Imagen", "Acciones"],
            data.datos.map((item) => [
                item.nombre,
                item.categoria,
                money(item.precio),
                { texto: item.activo ? "Activo" : "Inactivo", clase: item.activo ? "ok" : "bad" },
                { imagenProducto: item.id },
                { editarProducto: item.id },
            ])
        );
    } catch (error) {
        toast(error.message);
    }
}

let versionFormularioProducto = 0;
async function modificarProducto(id) {
    if (formulariosEnCurso.has('guardarProducto') || formulariosEnCurso.has('modificarProducto')) return;
    const version = ++versionFormularioProducto;
    try {
        const [respuesta, categorias] = await Promise.all([api(`/api/productos/${Number(id)}`), api('/api/categorias')]);
        if (version !== versionFormularioProducto) return;
        const producto = respuesta.datos;
        const form = $('#formProducto');
        delete form.dataset.productoCreado;
        form.classList.remove('hidden');
        form.innerHTML = `
            <h3>Modificar producto</h3>
            <div class="formgrid">
                <label>Nombre<input id="editarNombre" class="field" maxlength="150" value="${escapar(producto.nombre)}"></label>
                <label>Precio<input id="editarPrecio" class="field" type="number" min="0.01" step="0.01" value="${escapar(producto.precio)}"></label>
                <label>Categoría<select id="editarCategoria" class="field">${categorias.datos.map(c => `<option value="${Number(c.id)}" ${Number(c.id) === Number(producto.categoria_id) ? 'selected' : ''}>${escapar(c.nombre)}</option>`).join('')}</select></label>
                <label>Descripción<textarea id="editarDescripcion" class="field">${escapar(producto.descripcion || '')}</textarea></label>
            </div>
            <label><input id="editarActivo" type="checkbox" ${producto.activo ? 'checked' : ''}> Producto activo</label>
            <p>El nuevo precio se aplica a futuras ventas. Los SKU, las variantes, el stock y las ventas anteriores se conservan.</p>
            <p id="editarMensaje" role="status"></p>
            <div class="formactions">
                <button id="editarGuardar" class="primary" type="button" onclick="guardarCambiosProducto(${Number(id)})">Guardar cambios</button>
                <button id="editarCancelar" type="button" onclick="$('#formProducto').classList.add('hidden')">Cancelar</button>
            </div>`;
        form.scrollIntoView({block:'start', behavior:'smooth'});
    } catch (error) { toast(error.message); }
}

async function guardarCambiosProducto(id) {
    if (formulariosEnCurso.has('modificarProducto')) return;
    formulariosEnCurso.add('modificarProducto');
    const controles = [...$('#formProducto').querySelectorAll('input, select, textarea, button')];
    const datos = {nombre: $('#editarNombre').value, precio: $('#editarPrecio').value,
        categoria_id: $('#editarCategoria').value, descripcion: $('#editarDescripcion').value,
        activo: $('#editarActivo').checked};
    controles.forEach(control => {control.disabled = true;});
    try {
        await api(`/api/productos/${Number(id)}`, {method:'PATCH', body:JSON.stringify(datos)});
        $('#formProducto').classList.add('hidden');
        toast('Producto modificado');
        await cargarProductos();
    } catch (error) {
        $('#editarMensaje').textContent = error.message;
        toast(error.message);
    } finally {
        controles.forEach(control => {control.disabled = false;});
        formulariosEnCurso.delete('modificarProducto');
    }
}

function mostrarProducto() {
    if (formulariosEnCurso.has('guardarProducto') || formulariosEnCurso.has('modificarProducto')) return;
    const version = ++versionFormularioProducto;
    const form = $("#formProducto");
    delete form.dataset.productoCreado;
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
                <select id="pc" class="field" onchange="$('#categoriaNuevaBox').classList.toggle('hidden', this.value !== 'nueva')"></select>
            </label>
            <label id="categoriaNuevaBox" class="hidden">
                Nueva categoría
                <input class="field" id="pcNueva" maxlength="100" placeholder="Nombre de la categoría">
            </label>
            <label>
                Descripcion
                <input class="field" id="pd">
            </label>
        </div>
        <label>Imagen del producto (opcional)
            <input id="pi" type="file" accept="image/png,image/jpeg,image/webp" onchange="previsualizarImagenProducto()">
        </label>
        <div id="previewProducto" class="hidden" aria-live="polite">
            <img id="previewProductoFoto" alt="Vista previa de la imagen del producto" style="display:block;max-width:220px;max-height:180px;object-fit:contain;margin:12px 0;border-radius:8px">
            <p id="previewProductoNombre"></p>
            <button type="button" onclick="$('#pi').value = ''; previsualizarImagenProducto();">Quitar imagen</button>
        </div>
        <h4>Variantes por talle y color</h4>
        <div class="formgrid">
            <label>Talles de este producto (separados por coma)
                <input id="pTalles" class="field" placeholder="S, M, L / 38, 40 / Único / Especial">
            </label>
            <label>Colores de este producto (separados por coma)
                <input id="pColores" class="field" placeholder="Negro, Blanco, Azul marino">
            </label>
        </div>
        <p>Podés usar letras, números, calzado (ej. 38.5), talle único o cualquier nombre especial. Solo se usarán los talles y colores que escribas.</p>
        <button type="button" onclick="try { actualizarGrillaProducto(); } catch(error) { toast(error.message); }">Armar / actualizar grilla</button>
        <p>Escribí el stock inicial en cada combinación. Dejá vacías las que no vendés; usá 0 para crear una variante sin stock.</p>
        <label>Stock mínimo por variante <input id="pMinimo" type="number" min="0" step="1" value="0"></label>
        <div id="grillaVariantes" class="grilla-variantes">Escribí tus talles y colores y presioná Armar grilla.</div>
        <div class="formactions">
            <button id="guardarProductoBtn" class="primary" onclick="guardarProducto()" disabled>Guardar producto y variantes</button>
            <button onclick="$(\'#formProducto\').classList.add(\'hidden\')">Cancelar</button>
        </div>
    `;

    form.scrollIntoView({block: 'start', behavior: 'smooth'});
    api("/api/categorias")
        .then((data) => {
            if (version !== versionFormularioProducto) return;
            $("#pc").innerHTML = data.datos
                .map((item) => `<option value="${escapar(item.id)}">${escapar(item.nombre)}</option>`)
                .join("") + '<option value="nueva">+ Crear nueva categoría</option>';
            $('#categoriaNuevaBox').classList.toggle('hidden', $('#pc').value !== 'nueva');
            $('#guardarProductoBtn').disabled = false;
        })
        .catch((error) => toast(error.message));
}

function actualizarGrillaProducto() {
    if ($('#formProducto').dataset.productoCreado) return;
    const lista = (selector, limite) => {
        const valores = $(selector).value.split(',').map(v => v.trim()).filter(Boolean);
        if (!valores.length || valores.some(v => v.length > limite)) throw new Error(`Ingresá nombres de hasta ${limite} caracteres para talles y colores.`);
        if (new Set(valores.map(v => v.toLocaleLowerCase())).size !== valores.length) throw new Error('No repitas talles ni colores.');
        return valores;
    };
    const talles = lista('#pTalles', 40), colores = lista('#pColores', 60);
    if (talles.length * colores.length > 200) throw new Error('La grilla admite hasta 200 combinaciones.');
    const anteriores = new Map($$('#grillaVariantes input').map(input => [JSON.stringify([input.dataset.talle, input.dataset.color]), input.value]));
    const claves = new Set(colores.flatMap(c => talles.map(t => JSON.stringify([t, c]))));
    if ([...anteriores].some(([clave, valor]) => valor !== '' && !claves.has(clave))) {
        throw new Error('Para quitar un talle o color, vaciá primero sus cantidades en la grilla.');
    }
    $('#grillaVariantes').innerHTML = `<table class="table"><thead><tr><th>Color / Talle</th>${talles.map(t => `<th scope="col">${escapar(t)}</th>`).join('')}</tr></thead><tbody>${colores.map(c => `<tr><th scope="row">${escapar(c)}</th>${talles.map(t => `<td><input class="stock-grilla" type="number" min="0" max="2147483647" step="1" placeholder="—" value="${escapar(anteriores.get(JSON.stringify([t,c])) || '')}" data-talle="${escapar(t)}" data-color="${escapar(c)}" aria-label="Stock ${escapar(c)} talle ${escapar(t)}"></td>`).join('')}</tr>`).join('')}</tbody></table>`;
}

async function guardarProducto() {
    if (formulariosEnCurso.has("guardarProducto")) return;
    formulariosEnCurso.add("guardarProducto");
    $('#guardarProductoBtn').disabled = true;
    try {
        if (!$('#formProducto').dataset.productoCreado) actualizarGrillaProducto();
        const imagen = $("#pi").files[0] ? await prepararImagen($("#pi").files[0]) : null;
        const form = $("#formProducto");
        const producto = {nombre: $('#pn').value, precio: $('#pp').value, descripcion: $('#pd').value};
        if ($('#pc').value !== 'nueva') producto.categoria_id = $('#pc').value;
        const variantes = $$('#grillaVariantes input').filter(input => input.value !== '').map(input => ({
            talle: input.dataset.talle, color: input.dataset.color, stock: input.value, stock_minimo: $('#pMinimo').value,
        }));
        const resultado = form.dataset.productoCreado ? {id: Number(form.dataset.productoCreado)} : await api("/api/productos/carga", {
            method: "POST",
            body: JSON.stringify({
                producto, variantes, categoria_nueva: $('#pc').value === 'nueva' ? $('#pcNueva').value : null,
            }),
        });
        form.dataset.productoCreado = resultado.id;
        // Si falla solo la foto, el reintento no crea otro producto ni variantes.
        form.querySelectorAll('input:not([type="file"]), select').forEach(input => { input.disabled = true; });
        if (imagen) await guardarImagenProducto(resultado.id, imagen);

        toast("Producto guardado");
        $("#formProducto").classList.add("hidden");
        cargarProductos();
    } catch (error) {
        toast($('#formProducto').dataset.productoCreado ? `Producto y variantes guardados. No se pudo guardar la foto: ${error.message}. Reintentá Guardar.` : error.message);
    } finally {
        formulariosEnCurso.delete("guardarProducto");
        $('#guardarProductoBtn').disabled = false;
    }
}

let versionPreviewProducto = 0;
async function previsualizarImagenProducto() {
    const version = ++versionPreviewProducto;
    const selector = $('#pi');
    const archivo = selector.files[0];
    $('#previewProducto').classList.add('hidden');
    $('#previewProductoFoto').removeAttribute('src');
    if (!archivo) return;
    try {
        const contenido = await prepararImagen(archivo);
        if (version !== versionPreviewProducto || selector !== $('#pi')) return;
        $('#previewProductoFoto').src = `data:image/jpeg;base64,${contenido}`;
        $('#previewProductoNombre').textContent = archivo.name;
        $('#previewProducto').classList.remove('hidden');
    } catch (error) {
        if (version !== versionPreviewProducto || selector !== $('#pi')) return;
        selector.value = '';
        toast(error.message);
    }
}

async function prepararImagen(archivo) {
    if (!['image/png', 'image/jpeg', 'image/webp'].includes(archivo.type) || archivo.size > 10 * 1024 * 1024) {
        throw new Error('Elegí una imagen JPG, PNG o WebP de hasta 10 MB.');
    }
    const bitmap = await createImageBitmap(archivo);
    try {
        const escala = Math.min(1, 1000 / Math.max(bitmap.width, bitmap.height));
        const canvas = document.createElement('canvas');
        canvas.width = Math.max(1, Math.round(bitmap.width * escala));
        canvas.height = Math.max(1, Math.round(bitmap.height * escala));
        const contexto = canvas.getContext('2d');
        contexto.fillStyle = '#ffffff';
        contexto.fillRect(0, 0, canvas.width, canvas.height);
        contexto.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
        const contenido = canvas.toDataURL('image/jpeg', 0.8).split(',')[1];
        if (contenido.length > 930000) throw new Error('La imagen es demasiado grande. Elegí una más pequeña.');
        return contenido;
    } finally { bitmap.close(); }
}

async function guardarImagenProducto(id, imagen) {
    await api(`/api/productos/${Number(id)}/imagen`, {method: 'POST', body: JSON.stringify({imagen})});
}

function cargarImagenExistente(id) {
    const selector = document.createElement('input');
    selector.type = 'file';
    selector.accept = 'image/png,image/jpeg,image/webp';
    selector.onchange = async () => {
        if (!selector.files[0]) return;
        try {
            await guardarImagenProducto(id, await prepararImagen(selector.files[0]));
            toast('Imagen guardada');
            await cargarPuntoVenta();
        } catch (error) { toast(error.message); }
    };
    selector.click();
}

function fotoProducto(id, nombre, clase = '') {
    return `<img class="foto-producto ${clase}" src="/api/productos/${Number(id)}/imagen" alt="${escapar(nombre)}" loading="lazy">`;
}

async function cargarInventario() {
    const version = ++busquedaInventario;
    try {
        const query = encodeURIComponent($("#busqStock")?.value || "");
        const bajo = $("#soloBajo")?.checked ? "&solo_bajo=true" : "";
        const data = await api(`/api/inventario?q=${query}${bajo}`);

        if (version !== busquedaInventario) return;
        tablaPaginada("#tablaInventario",
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
            ]), query + bajo
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
        tablaPaginada("#tablaVentas",
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
                ${fotoProducto(item.producto_id, item.producto)}
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
            producto_id: item.producto_id,
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
                        ${fotoProducto(item.producto_id || inventarioPOS.find(v => number(v.id) === item.variante_id)?.producto_id, item.nombre, 'foto-carrito')}
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
        const actualizaciones = await Promise.allSettled([cargarPuntoVenta(), cargarVentas(), cargarInventario(), cargarTodo()]);
        if (actualizaciones.some(resultado => resultado.status === 'rejected')) {
            toast(`Venta #${sale.id} confirmada. No se pudo actualizar algún panel; recargá la página.`);
        }
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

function dibujarGraficoVentas(filas) {
    const panel = $('#graficoVentas');
    const titulo = '<h3>Facturación neta por día</h3><p>Importes en pesos, con cambios y devoluciones descontados. Se muestran los días con movimientos.</p>';
    if (!filas.length) {
        panel.innerHTML = titulo + '<p class="mensaje-vacio">No hay movimientos en el período seleccionado.</p>';
        return;
    }
    const valores = filas.map(f => Number(f.total));
    const minimo = Math.min(0, ...valores), maximo = Math.max(0, ...valores);
    const rango = maximo - minimo || 1;
    const ancho = Math.max(800, filas.length * 38 + 110);
    const y = valor => 30 + (maximo - valor) / rango * 230;
    const paso = (ancho - 110) / filas.length;
    const fecha = f => String(f).slice(0, 10).split('-').reverse().join('/');
    const ejes = Array.from({length:5}, (_, i) => {
        const valor = maximo - rango * i / 4;
        return `<line x1="100" x2="${ancho - 10}" y1="${y(valor)}" y2="${y(valor)}" stroke="#e2e8f0"/><text x="92" y="${y(valor)+4}" text-anchor="end" font-size="11" fill="#64748b">${escapar(Number(valor.toFixed(0)).toLocaleString('es-AR'))}</text>`;
    }).join('');
    panel.innerHTML = titulo + `<div class="grafico-scroll"><svg role="img" aria-label="Facturación neta diaria en pesos" viewBox="0 0 ${ancho} 330" style="width:100%;min-width:${ancho}px;height:auto">${ejes}
        <line x1="100" x2="${ancho-10}" y1="${y(0)}" y2="${y(0)}" stroke="#94a3b8"/>
        ${filas.map((f,i) => {
            const valor = Number(f.total), x = 100 + i * paso + paso * .15;
            return `<rect tabindex="0" aria-label="${escapar(fecha(f.fecha))}: ${escapar(money(valor))}" x="${x}" y="${Math.min(y(valor),y(0))}" width="${paso*.7}" height="${Math.max(1,Math.abs(y(valor)-y(0)))}" rx="3" fill="${valor < 0 ? '#dc2626' : '#2563eb'}"><title>${escapar(fecha(f.fecha))}: ${escapar(money(valor))} · ${escapar(f.ventas)} ventas</title></rect><text transform="translate(${x+paso*.35},280) rotate(-40)" text-anchor="end" font-size="11" fill="#64748b">${escapar(fecha(f.fecha))}</text>`;
        }).join('')}</svg></div><details><summary>Ver datos del gráfico</summary>${table(['Fecha','Ventas','Facturación neta'], filas.map(f => [fecha(f.fecha),f.ventas,money(f.total)]))}</details>`;
}

let versionStats = 0;
async function cargarStats() {
    const version = ++versionStats;
    $('#graficoVentas').textContent = 'Cargando gráfico…';
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
        const [data, ranking, serie] = await Promise.all([
            api(`/api/estadisticas/resumen${query}`),
            api(`/api/estadisticas/productos${query}`),
            api(`/api/estadisticas/ventas-por-dia${query}`),
        ]);
        if (version !== versionStats) return;
        dibujarGraficoVentas(serie.datos);

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
        if (version !== versionStats) return;
        $('#graficoVentas').textContent = 'No se pudo cargar el gráfico. Revisá las fechas y volvé a consultar.';
        $('#statsCards').innerHTML = '';
        $('#ranking').innerHTML = '';
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
