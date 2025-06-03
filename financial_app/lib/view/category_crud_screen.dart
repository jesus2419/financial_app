import 'package:flutter/material.dart';
import '../database/database_handler.dart';
import '../model/category.dart';

class CategoryCrudScreen extends StatefulWidget {
  const CategoryCrudScreen({Key? key}) : super(key: key);

  @override
  State<CategoryCrudScreen> createState() => _CategoryCrudScreenState();
}

class _CategoryCrudScreenState extends State<CategoryCrudScreen> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = DatabaseHandler.instance.getAllCategories();
    });
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final formKey = GlobalKey<FormState>();
    String? name = category?.name;
    String type = category?.type ?? 'expense';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          category == null ? 'Agregar Categoría' : 'Editar Categoría',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
                onChanged: (val) => name = val,
              ),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Ingreso')),
                  DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                ],
                onChanged: (val) => type = val!,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final db = DatabaseHandler.instance;
                if (category == null) {
                  await db.addCategory(Category(name: name!, type: type));
                } else {
                  await db.addCategory(
                    Category(
                      id: category.id,
                      name: name!,
                      type: type,
                      icon: category.icon,
                      color: category.color,
                    ),
                  );
                }
                Navigator.pop(context);
                _refreshCategories();
              }
            },
            child: Text(category == null ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    final db = DatabaseHandler.instance;
    // No hay método deleteCategory, así que puedes agregarlo si lo necesitas
    // await db.deleteCategory(id);
    // Por ahora solo refresca
    _refreshCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar Categoría',
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay categorías registradas.'));
          }
          final categories = snapshot.data!;
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final cat = categories[i];
              return ListTile(
                leading: const Icon(Icons.category),
                title: Text(cat.name),
                subtitle: Text(cat.type == 'income' ? 'Ingreso' : 'Gasto'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showCategoryDialog(category: cat);
                    } else if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar categoría'),
                          content: const Text(
                            '¿Estás seguro de eliminar esta categoría?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _deleteCategory(cat.id!);
                              },
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
