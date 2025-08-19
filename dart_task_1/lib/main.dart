import 'dart:convert';

void main() {
  const String jsonString = '''
  {
    "animals": [
      { "animal": "dog,cat,dog,cow" },
      { "animal": "cow,cat,cat" },
      { "animal": null },
      { "animal": "" }
    ]
  }
  ''';

  // Decode JSON into a Dart Map
  final Map<String, dynamic> jsonData = json.decode(jsonString);

  // Extract the animals list from the JSON
  final List<dynamic> animalsList = jsonData["animals"];

  // Loop through each object in the animals list
  for (var item in animalsList) {
    final String? animalsString = item["animal"];

    // Skip if null or empty
    if (animalsString == null || animalsString.trim().isEmpty) {
      continue;
    }

    // Split the string into individual animals
    List<String> animalNames = animalsString.split(",");

    // Count occurrences using a Map
    final Map<String, int> countMap = {};
    for (var animal in animalNames) {
      animal = animal.trim(); // remove spaces if present
      countMap[animal] = (countMap[animal] ?? 0) + 1;
    }

    // Format the output
    List<String> formattedList = [];
    countMap.forEach((animal, count) {
      if (count > 1) {
        formattedList.add("$animal($count)");
      } else {
        formattedList.add(animal);
      }
    });

    // Print the joined string
    print(formattedList.join(", "));
  }
}
