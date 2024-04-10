  Widget _buildProductoCard(QueryDocumentSnapshot producto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)),
        ),
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color.fromARGB(255, 235, 235, 235)),
                      ),
                      child: SizedBox(
                        width: 150,
                        height: 180,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: Image.network(
                            producto['url'] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto['NOMBRE_DEL_PRODUCTO'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: "Poppins-l", fontSize: 11),
                          ),
                          const SizedBox(height: 0),
                          SizedBox(
                            width: 150,
                            child: Text(
                              producto['descripcion'] as String,
                              style: const TextStyle(fontSize: 10, fontFamily: "Poppins", color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 0),
                    Text(
                      '\$${producto['precio']}',
                      style: const TextStyle(fontSize: 12, fontFamily: "Poppins-l", fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 190,
                child: InkWell(
                  onTap: () {
                    _shoppingCart.addToCart(
                      producto['NOMBRE_DEL_PRODUCTO'] as String,
                      _getProductPrice(producto['NOMBRE_DEL_PRODUCTO'] as String),
                    );
                    setState(() {
                      _cartItemCount++;
                    });
                    // Agregar efecto de vibración
                    HapticFeedback.vibrate();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 247, 253, 246),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(Icons.add, color: Colors.green[800]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }






    Widget _buildProductoItem(QueryDocumentSnapshot producto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                producto['url'] as String,
                height: 100,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['NOMBRE_DEL_PRODUCTO'] as String,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    producto['descripcion'] as String,
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '\$${producto['precio']}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                _shoppingCart.addToCart(
                  producto['NOMBRE_DEL_PRODUCTO'] as String,
                  _getProductPrice(producto['NOMBRE_DEL_PRODUCTO'] as String),
                );
                setState(() {
                  _cartItemCount++;
                });
                HapticFeedback.vibrate();
              },
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                color: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Add to Cart',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
