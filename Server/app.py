import os
from flask import Flask, request, jsonify, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_migrate import Migrate
from werkzeug.utils import secure_filename
from flask_jwt_extended import jwt_required, get_jwt_identity

# ────────────────────────────────
# Configuración base de la aplicación
# ────────────────────────────────
app = Flask(__name__)
CORS(app)

# Configuración base de datos PostgreSQL
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:admin@localhost:5432/dbstoreapp'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

# Configuración para subir imágenes
UPLOAD_FOLDER = os.path.join(os.getcwd(), 'static', 'uploads')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Inicialización de extensiones
db = SQLAlchemy(app)
migrate = Migrate(app, db)

# ────────────────────────────────
# Modelos
# ────────────────────────────────

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)
    location = db.Column(db.String(255), nullable=False)
    estado = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    profile_image = db.Column(db.String(255), nullable=True)
    role = db.Column(db.String(50), nullable=False, default='cliente')  # 'cliente' o 'admin'

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'location': self.location,
            'estado': self.estado,
            'phone': self.phone,
            'profile_image': self.profile_image,
            'role': self.role,
        }
    
class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    category = db.Column(db.String(100), nullable=False)
    price = db.Column(db.Float, nullable=False)
    stock = db.Column(db.Integer, nullable=False)
    description = db.Column(db.Text, nullable=True)  # <-- campo nuevo
    image_url1 = db.Column(db.String(255), nullable=True)
    image_url2 = db.Column(db.String(255), nullable=True)
    image_url3 = db.Column(db.String(255), nullable=True)
    image_url4 = db.Column(db.String(255), nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'category': self.category,
            'price': self.price,
            'stock': self.stock,
            'description': self.description,  # <-- nuevo campo
            'image_url1': self.image_url1,
            'image_url2': self.image_url2,
            'image_url3': self.image_url3,
            'image_url4': self.image_url4,
        }



class Category(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False, unique=True)
    type = db.Column(db.String(50), nullable=False, default='grid')  # 'carrusel' o 'grid'
    index = db.Column(db.Integer, nullable=False, default=1, unique=True)  # índice único para orden

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'type': self.type,
            'index': self.index,
        }
class Order(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=True)
    name = db.Column(db.String(100), nullable=True)
    method = db.Column(db.String(50), nullable=False)
    total = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(50), default='pendiente')  # Opcional
    is_completed = db.Column(db.Boolean, default=False)  # Nuevo campo
    created_at = db.Column(db.DateTime, server_default=db.func.now())

    order_items = db.relationship('OrderItem', backref='order', cascade='all, delete-orphan')

class OrderItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('order.id'), nullable=False)
    product_id = db.Column(db.Integer, nullable=False)
    title = db.Column(db.String(100))
    price = db.Column(db.Float, nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
# ────────────────────────────────
# Funciones auxiliares
# ────────────────────────────────

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ────────────────────────────────
# Rutas Usuarios
# ────────────────────────────────

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    location = data.get('location')
    estado = data.get('estado')
    phone = data.get('phone')
    role = data.get('role', 'cliente')

    if not all([name, email, password, location, estado, phone]):
        return jsonify({'error': 'Todos los campos son requeridos'}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'Correo ya registrado'}), 409

    user = User(
        name=name,
        email=email,
        password=password,
        location=location,
        estado=estado,
        phone=phone,
        role=role
    )
    db.session.add(user)
    db.session.commit()

    return jsonify({'message': 'Usuario registrado correctamente'}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not all([email, password]):
        return jsonify({'error': 'Correo y contraseña son requeridos'}), 400

    user = User.query.filter_by(email=email).first()
    if user and user.password == password:
        return jsonify({'message': 'Inicio de sesión exitoso', 'user': user.to_dict()}), 200

    return jsonify({'error': 'Credenciales inválidas'}), 401

@app.route('/api/profile/<int:user_id>', methods=['GET'])
def get_profile(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    return jsonify(user.to_dict())

@app.route('/api/profile/<int:user_id>', methods=['PUT'])
def update_profile(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    data = request.form
    user.name = data.get('name', user.name)
    user.email = data.get('email', user.email)
    user.location = data.get('location', user.location)
    user.estado = data.get('estado', user.estado)
    user.phone = data.get('phone', user.phone)

    if 'image' in request.files:
        image = request.files['image']
        if image.filename:
            filename = secure_filename(image.filename)
            image_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            image.save(image_path)
            relative_path = os.path.relpath(image_path, start=os.getcwd())
            user.profile_image = "/" + relative_path.replace("\\", "/")

    db.session.commit()
    return jsonify({'message': 'Perfil actualizado', 'user': user.to_dict()}), 200

@app.route('/api/change_password', methods=['POST'])
def change_password():
    data = request.get_json()
    user_id = data.get('user_id')
    current_password = data.get('current_password')
    new_password = data.get('new_password')

    if not all([user_id, current_password, new_password]):
        return jsonify({'error': 'Faltan datos'}), 400

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    if user.password != current_password:
        return jsonify({'error': 'Contraseña actual incorrecta'}), 401

    user.password = new_password
    db.session.commit()

    return jsonify({'message': 'Contraseña actualizada correctamente'})

@app.route('/api/static/uploads/<filename>')
def serve_image(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/api/users', methods=['GET'])
def get_users():
    users = User.query.all()
    return jsonify([u.to_dict() for u in users])

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    user = User.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    return jsonify({'message': 'User deleted'})

@app.route('/api/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    user = User.query.get_or_404(user_id)
    data = request.get_json()

    user.name = data.get('name', user.name)
    user.email = data.get('email', user.email)
    user.role = data.get('role', user.role)
    user.phone = data.get('phone', user.phone)
    user.location = data.get('location', user.location)
    user.estado = data.get('estado', user.estado)

    if '@' not in user.email:
        return jsonify({'error': 'Correo inválido'}), 400

    db.session.commit()
    return jsonify(user.to_dict())

# ────────────────────────────────
# Rutas Productos
# ────────────────────────────────

# Ruta POST para agregar producto, incluyendo descripción
@app.route('/api/products', methods=['POST'])
def add_product():
    name = request.form.get('name')
    category = request.form.get('category')
    price = request.form.get('price')
    stock = request.form.get('stock')
    description = request.form.get('description')  # <-- nuevo

    files = [request.files.get(f'image{i}') for i in range(1, 5)]

    if not all([name, category, price, stock]):
        return jsonify({'error': 'Todos los campos son obligatorios'}), 400

    image_urls = []
    for file in files:
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(save_path)
            relative_path = os.path.relpath(save_path, start=os.getcwd())
            image_urls.append("/" + relative_path.replace("\\", "/"))
        else:
            image_urls.append(None)

    new_product = Product(
        name=name,
        category=category,
        price=float(price),
        stock=int(stock),
        description=description,  # <-- nuevo
        image_url1=image_urls[0],
        image_url2=image_urls[1],
        image_url3=image_urls[2],
        image_url4=image_urls[3]
    )

    db.session.add(new_product)
    db.session.commit()

    return jsonify({'message': 'Producto agregado con éxito', 'product': new_product.to_dict()}), 201


# Ruta PUT para actualizar producto, incluyendo descripción
@app.route('/api/products/<int:product_id>', methods=['PUT'])
def update_product(product_id):
    product = Product.query.get_or_404(product_id)
    data = request.form

    product.name = data.get('name', product.name)
    product.category = data.get('category', product.category)
    product.price = float(data.get('price', product.price))
    product.stock = int(data.get('stock', product.stock))
    product.description = data.get('description', product.description)  # <-- nuevo

    files = [request.files.get(f'image{i}') for i in range(1, 5)]
    for i, file in enumerate(files, start=1):
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(save_path)
            relative_path = os.path.relpath(save_path, start=os.getcwd())
            setattr(product, f'image_url{i}', "/" + relative_path.replace("\\", "/"))

    db.session.commit()
    return jsonify(product.to_dict())

@app.route('/api/products', methods=['GET'])
def get_products():
    category_name = request.args.get('category', type=str)

    query = Product.query

    if category_name:
        # Filtra productos cuyo campo category contiene la cadena, sin importar mayúsculas/minúsculas
        query = query.filter(Product.category.ilike(f'%{category_name}%'))

    products = query.all()
    return jsonify([p.to_dict() for p in products])


@app.route('/api/products/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    product = Product.query.get_or_404(product_id)
    db.session.delete(product)
    db.session.commit()
    return jsonify({'message': 'Producto eliminado'})

@app.route('/api/products/<int:product_id>/stock', methods=['PUT'])
def update_product_stock(product_id):
    product = Product.query.get_or_404(product_id)
    data = request.get_json()

    new_stock = data.get('stock')
    if new_stock is None or not isinstance(new_stock, int) or new_stock < 0:
        return jsonify({'error': 'Stock inválido'}), 400

    product.stock = new_stock
    db.session.commit()

    return jsonify({'id': product.id, 'stock': product.stock}), 200
# ────────────────────────────────
# Rutas Categorías
# ────────────────────────────────

@app.route('/api/categories', methods=['POST'])
def create_category():
    data = request.get_json()
    name = data.get('name')
    ctype = data.get('type', 'carrusel')

    if not name:
        return jsonify({'error': 'El nombre es requerido'}), 400

    if ctype not in ('carrusel', 'grid'):
        return jsonify({'error': 'Tipo inválido, debe ser carrusel o grid'}), 400

    if Category.query.filter_by(name=name).first():
        return jsonify({'error': 'Categoría ya existe'}), 409

    category = Category(name=name, type=ctype)
    db.session.add(category)
    db.session.commit()

    return jsonify(category.to_dict()), 201

@app.route('/api/categories', methods=['GET'])
def get_categories():
    categories = Category.query.all()
    return jsonify([c.to_dict() for c in categories])

@app.route('/api/categories/<int:category_id>', methods=['GET'])
def get_category(category_id):
    category = Category.query.get_or_404(category_id)
    return jsonify(category.to_dict())

@app.route('/api/categories/<int:category_id>', methods=['PUT'])
def update_category(category_id):
    category = Category.query.get_or_404(category_id)
    data = request.get_json()

    name = data.get('name', category.name)
    ctype = data.get('type', category.type)

    if not name:
        return jsonify({'error': 'El nombre es requerido'}), 400

    if ctype not in ('carrusel', 'grid'):
        return jsonify({'error': 'Tipo inválido, debe ser carrusel o grid'}), 400

    existing = Category.query.filter(Category.name == name, Category.id != category_id).first()
    if existing:
        return jsonify({'error': 'Otra categoría con ese nombre ya existe'}), 409

    category.name = name
    category.type = ctype
    db.session.commit()

    return jsonify(category.to_dict())

@app.route('/api/categories/<int:category_id>/has-products', methods=['GET'])
def category_has_products(category_id):
    category = Category.query.get_or_404(category_id)
    # Contar productos con esa categoría (según cómo lo tengas en Product)
    count = Product.query.filter(Product.category == category.name).count()
    return jsonify({'has_products': count > 0})

@app.route('/api/categories/<int:category_id>/swap-index', methods=['PUT'])
def update_category_swap_index(category_id):
    category = Category.query.get_or_404(category_id)
    data = request.get_json()

    new_index = data.get('new_index')
    ctype = data.get('type', category.type)



    if ctype not in ('carrusel', 'grid'):
        return jsonify({'error': 'Tipo inválido, debe ser carrusel o grid'}), 400

    if new_index is None or not isinstance(new_index, int) or new_index < 1:
        return jsonify({'error': 'Índice inválido'}), 400



    # Buscar la categoría que tiene el índice nuevo
    swap_cat = Category.query.filter_by(index=new_index).first()

    if swap_cat and swap_cat.id != category_id:
        # Hacer swap cíclico de índices
        old_index = category.index
        category.index = new_index
        swap_cat.index = old_index
        db.session.commit()
    else:
        # No hay categoría con ese índice, solo actualizar
        category.index = new_index
        db.session.commit()
    category.type = ctype
    db.session.commit()

    return jsonify(category.to_dict())
@app.route('/api/categories/<int:category_id>', methods=['DELETE'])
def delete_category(category_id):
    category = Category.query.get_or_404(category_id)
    db.session.delete(category)
    db.session.commit()
    return jsonify({'message': 'Categoría eliminada exitosamente'})

# ordenes
@app.route('/api/orders', methods=['GET'])
def get_orders():
    only_pending = request.args.get('pending')
    if only_pending == 'true':
        orders = Order.query.filter_by(is_completed=False).all()
    else:
        orders = Order.query.filter_by(is_completed=True).all()

    result = []
    for o in orders:
        user = User.query.filter_by(id=o.user_id).first()
        result.append({
            'id': o.id,
            'total': o.total,
            'method': o.method,
            'is_completed': o.is_completed,
            'created_at': o.created_at.isoformat(),
            'items': [
                {
                    'product_id': i.product_id,
                    'title': i.title,
                    'price': i.price,
                    'quantity': i.quantity,
                    'subtotal': i.price * i.quantity
                } for i in o.order_items
            ],
            'user': {
                'name': user.name if user else 'Sin nombre',
                'phone': user.phone if user else 'No disponible',
                'location': user.location if user else 'No disponible',
                'estado': user.estado if user else 'No disponible',
            }
        })
    return jsonify(result)

@app.route('/api/orders/<int:order_id>/complete', methods=['PATCH'])
def complete_order(order_id):
    order = Order.query.get_or_404(order_id)

    if order.is_completed:
        return jsonify({'error': 'El pedido ya está completado'}), 400

    # Validar stock para cada producto en el pedido
    for item in order.order_items:
        product = Product.query.get(item.product_id)
        if not product:
            return jsonify({'error': f'Producto con ID {item.product_id} no encontrado'}), 404
        if product.stock < item.quantity:
            return jsonify({
                'error': f'Stock insuficiente para el producto "{product.title}". '
                         f'Stock disponible: {product.stock}, requerido: {item.quantity}'
            }), 400

    # Descontar stock
    for item in order.order_items:
        product = Product.query.get(item.product_id)
        product.stock -= item.quantity
        if product.stock < 0:
            product.stock = 0  # evitar valores negativos, aunque debería estar validado antes

    # Marcar pedido como completado
    order.is_completed = True
    db.session.commit()

    return jsonify({'message': 'Pedido finalizado correctamente'})

@app.route('/api/orders', methods=['POST'])
def create_order():
    data = request.get_json()
    try:
        user_id = data.get('user_id')
        name = data.get('name')
        method = data.get('payment_method')
        total = data.get('total')
        items = data.get('items')
        is_completed = data.get('is_completed', False)

        # Validaciones básicas
        if not user_id or not method or not total or not items:
            print("faltan datos")
            return jsonify({'error': 'Faltan datos obligatorios'}), 400

        if not isinstance(items, list) or len(items) == 0:
            print("productos no hay")
            return jsonify({'error': 'La orden debe tener al menos un producto'}), 400

        new_order = Order(
            user_id=user_id,
            name=name,
            method=method,
            total=float(total),
            is_completed=is_completed
        )
        db.session.add(new_order)
        db.session.flush()  # Para obtener el ID del pedido antes del commit

        for item in items:
            order_item = OrderItem(
                order_id=new_order.id,
                product_id=item['product_id'],
                title=item['title'],
                price=item['unit_price'],
                quantity=item['quantity']
            )
            db.session.add(order_item)

        db.session.commit()

        return jsonify({'message': 'Orden registrada con éxito', 'order_id': new_order.id}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error al procesar la orden: {str(e)}'}), 500

@app.route('/api/orders/<int:order_id>', methods=['DELETE'])
def delete_order(order_id):
    order = Order.query.get_or_404(order_id)
    db.session.delete(order)
    db.session.commit()
    return jsonify({'message': 'Pedido eliminado correctamente'})

@app.route('/api/my-orders', methods=['GET'])
def get_my_orders():
    user_id = request.args.get('user_id', type=int)
    status = request.args.get('status')  # 'completed', 'pending' o None

    if not user_id:
        return jsonify({'error': 'Se requiere user_id'}), 400

    query = Order.query.filter_by(user_id=user_id)
    if status == 'completed':
        query = query.filter_by(is_completed=True)
    elif status == 'pending':
        query = query.filter_by(is_completed=False)

    orders = query.all()

    result = []
    for o in orders:
        user = User.query.filter_by(id=o.user_id).first()
        result.append({
            'id': o.id,
            'total': o.total,
            'method': o.method,
            'is_completed': o.is_completed,
            'created_at': o.created_at.isoformat(),
            'items': [
                {
                    'product_id': i.product_id,
                    'title': i.title,
                    'price': i.price,
                    'quantity': i.quantity,
                    'subtotal': i.price * i.quantity
                } for i in o.order_items
            ],
            'user': {
                'name': user.name if user else 'Sin nombre',
                'phone': user.phone if user else 'No disponible',
                'location': user.location if user else 'No disponible',
                'estado': user.estado if user else 'No disponible',
            }
        })
    return jsonify(result)
# ────────────────────────────────
# Ruta base
# ────────────────────────────────
@app.route('/')
def index():
    return "✅ API de STORE corriendo correctamente"

# ────────────────────────────────
# Crear tablas si no existen
# ────────────────────────────────
with app.app_context():
    db.create_all()

# ────────────────────────────────
# Ejecutar servidor
# ────────────────────────────────
if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True)
