from flask import Blueprint, render_template, request, jsonify, redirect, url_for, flash
from app.services.postventa import PostventaService, PostventaError
from app.services import NoEncontrado

postventa_bp = Blueprint('postventa', __name__)
postventa_service = PostventaService()


@postventa_bp.route('/postventa', methods=['GET'])
def index():
    return render_template('postventa.html')


@postventa_bp.route('/postventa/registrar', methods=['POST'])
def registrar():
    try:
        data = request.get_json(silent=True) or request.form.to_dict()
        resultado = postventa_service.registrar_operacion(data)
        
        if request.is_json:
            return jsonify({"exito": True, "data": resultado}), 200
        
        flash("Operación de posventa registrada exitosamente.", "success")
        return redirect(url_for('postventa.index'))

    except (PostventaError, NoEncontrado, ValueError) as e:
        if request.is_json:
            return jsonify({"exito": False, "error": str(e)}), 400
        
        flash(str(e), "danger")
        return redirect(url_for('postventa.index'))