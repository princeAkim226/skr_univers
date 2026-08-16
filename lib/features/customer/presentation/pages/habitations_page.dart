import 'package:flutter/material.dart';
import '../widgets/habitations_list.dart';

class HabitationsPage extends StatefulWidget {
  const HabitationsPage({Key? key}) : super(key: key);

  @override
  State<HabitationsPage> createState() => _HabitationsPageState();
}

class _HabitationsPageState extends State<HabitationsPage> {
  String mode = 'Vente'; // ou 'Location'
  String selectedType = 'Tous'; // magasin, maison, terrain...
  String selectedZone = 'Ma zone'; // à relier à la géolocalisation
  bool certifiedFirst = true;
  RangeValues priceRange = const RangeValues(10000, 1000000);
  int? selectedBedrooms;

  // TODO : Charger dynamiquement types, zones, produits depuis le backend !

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Habitation (${mode == "Vente" ? "Vente" : "Location"})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Ouvrir modal de filtres avancés
              showModalBottomSheet(
                context: context,
                builder: (context) => buildFilters(context),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Choix entre Vente et Location
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: [mode == 'Location', mode == 'Vente'],
              onPressed: (i) {
                setState(() {
                  mode = i == 0 ? 'Location' : 'Vente';
                });
                // TODO : recharger les produits filtrés !
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text('Location'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text('Vente'),
                ),
              ],
            ),
          ),
          // Curseur pour prioriser les vendeurs certifiés
          SwitchListTile(
            title: Text('Afficher d\'abord les vendeurs certifiés'),
            value: certifiedFirst,
            onChanged: (v) => setState(() => certifiedFirst = v),
          ),
          // Affichage des biens (à filtrer selon paramètres)
          Expanded(
            child: HabitationsList(
              mode: mode,
              type: selectedType,
              zone: selectedZone,
              certifiedFirst: certifiedFirst,
              priceRange: priceRange,
              bedrooms: selectedBedrooms,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFilters(BuildContext context) {
    // Ici tu ajoutes tous les filtres : type, zone, prix, chambres, etc.
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Type de propriété'),
          DropdownButton<String>(
            value: selectedType,
            items: ['Tous', 'Maison', 'Magasin', 'Terrain', 'Résidence']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => selectedType = v!),
          ),
          const SizedBox(height: 16),
          Text('Zone'),
          DropdownButton<String>(
            value: selectedZone,
            items: ['Ma zone', 'Zone A', 'Zone B', 'Zone C']
                .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                .toList(),
            onChanged: (v) => setState(() => selectedZone = v!),
          ),
          const SizedBox(height: 16),
          Text('Nombre de chambres'),
          DropdownButton<int?>(
            value: selectedBedrooms,
            hint: const Text("Tous"),
            items: [null, 1, 2, 3, 4, 5].map((n) => DropdownMenuItem(value: n, child: Text(n == null ? 'Tous' : '$n'))).toList(),
            onChanged: (v) => setState(() => selectedBedrooms = v),
          ),
          const SizedBox(height: 16),
          Text('Prix'),
          RangeSlider(
            min: 10000,
            max: 10000000,
            divisions: 100,
            values: priceRange,
            onChanged: (r) => setState(() => priceRange = r),
            labels: RangeLabels(
              priceRange.start.round().toString(),
              priceRange.end.round().toString(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO : appliquer les filtres
            },
            child: const Text('Appliquer'),
          )
        ],
      ),
    );
  }
}
