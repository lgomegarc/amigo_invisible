import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/whatsapp_service.dart';
import '../services/user_id_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetalleSorteoScreen extends StatefulWidget {
  final String sorteoId;
  final String nombre;
  final double presupuesto;
  final int codigo;
  final String creadorId;

  const DetalleSorteoScreen({
    super.key,
    required this.sorteoId,
    required this.nombre,
    required this.presupuesto,
    required this.codigo,
    required this.creadorId,
  });

  @override
  State<DetalleSorteoScreen> createState() => _DetalleSorteoScreenState();
}

class _DetalleSorteoScreenState extends State<DetalleSorteoScreen> {
  final Random _random = Random();
  String? _usuarioId;
  String? _miResultado;
  bool _sorteoHecho = false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final id = await getOrCreateUserId();
    setState(() => _usuarioId = id);

    final sorteoSnapshot = await FirebaseFirestore.instance
        .collection('sorteos')
        .doc(widget.sorteoId)
        .get();

    final dataSorteo = sorteoSnapshot.data() ?? {};
    _sorteoHecho = dataSorteo['sorteoHecho'] ?? false;

    final resultadosDoc = FirebaseFirestore.instance
        .collection('sorteos')
        .doc(widget.sorteoId)
        .collection('resultados')
        .doc(id);

    resultadosDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      final regalaA = snapshot.data()?['regalaA'] ?? 'Nadie';
      final visto = snapshot.data()?['visto'] ?? false;

      setState(() => _miResultado = regalaA);

      if (!visto) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('¡Sorteo realizado!'),
            content: Text('Debes regalar a: $regalaA'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );

        await resultadosDoc.update({'visto': true});
      }
    });
  }

  ButtonStyle _botonEstilo() => ElevatedButton.styleFrom(
    backgroundColor: Colors.lightBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 36),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  );

  Future<void> _realizarSorteo() async {
    final participantesSnap = await FirebaseFirestore.instance
        .collection('sorteos')
        .doc(widget.sorteoId)
        .collection('participantes')
        .get();

    final participantesDocs = participantesSnap.docs;

    if (participantesDocs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se necesitan al menos 2 participantes')),
      );
      return;
    }

    final participantes = participantesDocs
        .map((doc) => {
      'id': doc.id,
      'nombre': doc.data()['nombre'] ?? 'Sin nombre',
    })
        .toList();

    List<Map<String, dynamic>> receptores = List.from(participantes);

    bool valido = false;
    int intentos = 0;

    while (!valido && intentos < 3000) {
      receptores.shuffle(_random);
      valido = true;

      for (int i = 0; i < participantes.length; i++) {
        if (participantes[i]['id'] == receptores[i]['id']) {
          valido = false;
          break;
        }
      }
      intentos++;
    }

    if (!valido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo generar el sorteo. Intenta de nuevo.')),
      );
      return;
    }

    final resultadosRef = FirebaseFirestore.instance
        .collection('sorteos')
        .doc(widget.sorteoId)
        .collection('resultados');

    for (int i = 0; i < participantes.length; i++) {
      await resultadosRef.doc(participantes[i]['id']).set({
        'regalaA': receptores[i]['nombre'],
        'visto': false,
      });
    }

    await FirebaseFirestore.instance
        .collection('sorteos')
        .doc(widget.sorteoId)
        .update({'sorteoHecho': true});

    setState(() => _sorteoHecho = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sorteo realizado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorteoRef =
    FirebaseFirestore.instance.collection('sorteos').doc(widget.sorteoId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Código + WhatsApp
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Código del sorteo: ${widget.codigo}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                  tooltip: 'Enviar código por WhatsApp',
                  onPressed: () async {
                    try {
                      await WhatsappService.enviarCodigo(widget.codigo);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'Presupuesto: ${widget.presupuesto.toStringAsFixed(2)} €',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 16),

            const Text(
              'Participantes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            /// LISTA PARTICIPANTES
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: sorteoRef
                    .collection('participantes')
                    .orderBy('nombre')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index < docs.length) {
                        final doc = docs[index];
                        final data =
                            doc.data() as Map<String, dynamic>? ?? {};
                        final nombre = data['nombre'] ?? 'Sin nombre';

                        return ListTile(
                          title: Text(nombre),
                          trailing: (_usuarioId == widget.creadorId &&
                              !_sorteoHecho)
                              ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async => doc.reference.delete(),
                          )
                              : null,
                        );
                      }

                      /// 👉 ESTA ES LA FILA DEL FINAL: AQUÍ VA EL BOTÓN
                      return Column(
                        children: [
                          if (_miResultado != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Debes regalar a: $_miResultado',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          /// ✔️ BOTÓN JUSTO DEBAJO DE LOS PARTICIPANTES
                          if (_usuarioId == widget.creadorId && !_sorteoHecho)
                            Center(
                              child: ElevatedButton(
                                onPressed: _realizarSorteo,
                                style: _botonEstilo(),
                                child: const Text('Realizar sorteo'),
                              ),
                            ),

                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
