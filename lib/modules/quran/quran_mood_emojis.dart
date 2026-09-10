import 'quran_mood_models.dart';

/// Emojis for "read by how you feel", chosen in the app so the category data
/// keeps its shared seven-key format. Anything not listed — such as a category
/// an admin publishes later — falls back to its section's emoji.
const Map<String, String> _sectionEmojis = {
  'emotions': '💭',
  'faith_and_worship': '🕌',
  'hardships_and_decisions': '🌧️',
  'relationships_and_character': '🤝',
};

const Map<String, String> _categoryEmojis = {
  // Emotions
  'sadness_and_distress': '😔',
  'feeling_lost_and_seeking_guidance': '🧭',
  'anxiety_and_overthinking': '😟',
  'fear_of_the_future': '🌫️',
  'loneliness_and_feeling_unseen': '😶',
  'despair_and_loss_of_hope': '🥀',
  'regret_and_missed_opportunities': '😞',
  'bereavement_and_calamity': '🖤',
  // Faith and worship
  'repentance_and_returning_to_allah': '🤲',
  'strengthening_faith_and_certainty': '🌱',
  'hardness_of_heart_and_lack_of_humility': '🧊',
  'spiritual_fatigue_and_renewing_worship': '🔋',
  'supplication_and_waiting': '⏳',
  'resisting_temptation_and_leaving_sin': '🛡️',
  'meaning_and_purpose_of_life': '🌌',
  'seeking_refuge_from_whispers_and_evil': '🕊️',
  // Hardships and decisions
  'enduring_trials_with_patience': '⛰️',
  'injustice_and_oppression': '⚖️',
  'betrayal_by_someone_close': '💔',
  'anger_and_the_urge_to_retaliate': '😤',
  'financial_hardship_and_worry': '💸',
  'uncertainty_about_an_important_decision': '🤔',
  'not_understanding_what_happened': '🌀',
  'illness_and_pain': '🤒',
  // Relationships and character
  'improving_marital_relationships': '💞',
  'strained_relationship_with_parents': '👪',
  'raising_children_and_family_wellbeing': '🏡',
  'choosing_good_company': '👥',
  'comparison_and_envy': '👀',
  'avoiding_suspicion_backbiting_and_hurtful_speech': '🤐',
  'gratitude_for_blessings_and_success': '🌟',
  'worldly_attachment_and_remembering_the_hereafter': '🕰️',
};

const _fallback = '✨';

String sectionEmoji(String sectionId) => _sectionEmojis[sectionId] ?? _fallback;

String categoryEmoji(MoodCategory category) =>
    _categoryEmojis[category.id] ?? sectionEmoji(category.sectionId);
