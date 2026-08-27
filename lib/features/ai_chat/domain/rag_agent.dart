class RagAgent {
  final String id;
  final String label;

  const RagAgent({
    required this.id,
    required this.label,
  });
}

class RagAgents {
  static const medecinGeneraliste = RagAgent(
    id: 'medecin_generaliste',
    label: 'General practitioner',
  );

  static const dermatologue = RagAgent(
    id: 'dermatologue',
    label: 'Dermatologist',
  );

  static const nutritionniste = RagAgent(
    id: 'nutritionniste',
    label: 'Nutritionist',
  );

  static const psychologue = RagAgent(
    id: 'psychologue',
    label: 'Psychologist',
  );

  static const all = <RagAgent>[
    medecinGeneraliste,
    dermatologue,
    nutritionniste,
    psychologue,
  ];

  static RagAgent byId(String id) {
    return all.firstWhere(
      (a) => a.id == id,
      orElse: () => medecinGeneraliste,
    );
  }
}
