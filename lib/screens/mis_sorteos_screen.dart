// mis_sorteos_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_id_service.dart';
import 'detalle_sorteo_screen.dart';

class MisSorteosScreen extends StatefulWidget {
  const MisSorteosScreen({super.key});

  @override
  State<MisSorteosScreen> createState() => _MisSorteosScreenState();
}

class _MisSorteosScreenState extends State<MisSorteosScreen> {
  final TextEditingController _crearNombreUsuarioController = TextEditingController();
  final TextEditingController _crearNombreSorteoController = TextEditingController();
  final TextEditingController _crearPresupuestoController = TextEditingController();

  final TextEditingController _unirseNombreUsuarioController = TextEditingController();
  final TextEditingController _codigoUnirseController = TextEditingController();

  String? _usuarioId;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  @override
  void dispose() {
    _crearNombreUsuarioController.dispose();
    _crearNombreSorteoController.dispose();
    _crearPresupuestoController.dispose();
    _unirseNombreUsuarioController.dispose();
    _codigoUnirseController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final id = await getOrCreateUserId();
    setState(() => _usuarioId = id);
  }

  int _generarCodigo4Digitos() {
    final random = Random();
    return 1000 + random.nextInt(9000);
  }

  ButtonStyle _botonEstilo() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _crearSorteo() async {
    if (_usuarioId == null) return;

    final nombreUsuario = _crearNombreUsuarioController.text.trim();
    final nombreSorteo = _crearNombreSorteoController.text.trim();
    final presupuestoTexto = _crearPresupuestoController.text.trim();

    if (nombreUsuario.isEmpty || nombreSorteo.isEmpty || presupuestoTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos')),
      );
      return;
    }

    final presupuesto = double.tryParse(presupuestoTexto);
    if (presupuesto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presupuesto no válido')),
      );
      return;
    }

    final codigo = _generarCodigo4Digitos();

    final docRef = await FirebaseFirestore.instance.collection('sorteos').add({
      'nombre': nombreSorteo,
      'presupuesto': presupuesto,
      'codigo': codigo,
      'creadorId': _usuarioId,
      'creadorNombre': nombreUsuario,
      'sorteoHecho': false,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'participantesIds': [_usuarioId],
    });

    await docRef.collection('participantes').doc(_usuarioId).set({
      'usuarioId': _usuarioId,
      'nombre': nombreUsuario,
    });

    _crearNombreUsuarioController.clear();
    _crearNombreSorteoController.clear();
    _crearPresupuestoController.clear();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleSorteoScreen(
          sorteoId: docRef.id,
          nombre: nombreSorteo,
          presupuesto: presupuesto,
          codigo: codigo,
          creadorId: _usuarioId!,
        ),
      ),
    );
  }

  Future<void> _unirsePorCodigo() async {
    if (_usuarioId == null) return;

    final nombreUsuario = _unirseNombreUsuarioController.text.trim();
    final codigoTexto = _codigoUnirseController.text.trim();

    if (nombreUsuario.isEmpty || codigoTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos')),
      );
      return;
    }

    final codigo = int.tryParse(codigoTexto);
    if (codigo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código no válido')),
      );
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('sorteos')
        .where('codigo', isEqualTo: codigo)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No existe un sorteo con ese código')),
      );
      return;
    }

    final doc = query.docs.first;
    final data = doc.data() as Map<String, dynamic>? ?? {};

    await doc.reference.collection('participantes').doc(_usuarioId).set({
      'usuarioId': _usuarioId,
      'nombre': nombreUsuario,
    });

    await doc.reference.update({
      'participantesIds': FieldValue.arrayUnion([_usuarioId])
    });

    _unirseNombreUsuarioController.clear();
    _codigoUnirseController.clear();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleSorteoScreen(
          sorteoId: doc.id,
          nombre: data['nombre'] ?? 'Sin nombre',
          presupuesto: (data['presupuesto'] as num?)?.toDouble() ?? 0,
          codigo: data['codigo'] ?? 0,
          creadorId: data['creadorId'] ?? '',
        ),
      ),
    );
  }

  Future<void> _eliminarMiParticipacion(String sorteoId) async {
    final userId = _usuarioId;

    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('sorteos')
        .doc(sorteoId)
        .update({
      'participantesIds': FieldValue.arrayRemove([userId])
    });

    await FirebaseFirestore.instance
        .collection('sorteos')
        .doc(sorteoId)
        .collection('participantes')
        .doc(userId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (_usuarioId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Stream<QuerySnapshot> sorteosStream =
    FirebaseFirestore.instance.collection('sorteos').snapshots();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(),
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CREAR SORTEO
                    Text(
                      'Crear sorteo',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _crearNombreUsuarioController,
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre (creador)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _crearNombreSorteoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del sorteo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _crearPresupuestoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Presupuesto (€)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: _crearSorteo,
                        style: _botonEstilo(),
                        child: const Text('Crear sorteo'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // UNIRSE A SORTEO
                    Text(
                      'Unirme a un sorteo',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _unirseNombreUsuarioController,
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codigoUnirseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Código del sorteo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: _unirsePorCodigo,
                        style: _botonEstilo(),
                        child: const Text('Unirse al sorteo'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // LISTA DE SORTEOS
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sorteos en los que participo',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Lista scrollable con altura flexible
                    SizedBox(
                      height: 400, // o constraints.maxHeight * 0.4 si quieres relativo
                      child: StreamBuilder<QuerySnapshot>(
                        stream: sorteosStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final all = snapshot.data!.docs;
                          final misSorteos = all.where((doc) {
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            final list = data['participantesIds'];
                            return list is List && list.contains(_usuarioId);
                          }).toList();

                          if (misSorteos.isEmpty) {
                            return const Center(
                                child: Text('Aún no participas en ningún sorteo'));
                          }

                          return ListView.builder(
                            itemCount: misSorteos.length,
                            itemBuilder: (context, index) {
                              final d = misSorteos[index];
                              final data = d.data() as Map<String, dynamic>? ?? {};

                              return ListTile(
                                title: Text(data['nombre'] ?? 'Sin nombre'),
                                subtitle: Text(
                                  '€${(data['presupuesto'] as num?)?.toDouble().toString()} • Código: ${data['codigo']}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'eliminar') {
                                      _eliminarMiParticipacion(d.id);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'eliminar',
                                      child: Text('Eliminar sorteo'),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetalleSorteoScreen(
                                        sorteoId: d.id,
                                        nombre: data['nombre'] ?? 'Sin nombre',
                                        presupuesto:
                                        (data['presupuesto'] as num?)?.toDouble() ??
                                            0,
                                        codigo: data['codigo'] ?? 0,
                                        creadorId: data['creadorId'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
