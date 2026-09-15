import 'package:flutter/material.dart';

import 'quran_mood_models.dart';

/// Icons for "read by how you feel", chosen in the app so the category data
/// keeps its shared format. Anything not listed — such as a category an admin
/// publishes later — falls back to its section's icon.
const Map<String, IconData> _sectionIcons = {
  'emotions': Icons.favorite_rounded,
  'faith_and_worship': Icons.mosque_rounded,
  'hardships_and_decisions': Icons.landscape_rounded,
  'relationships_and_character': Icons.diversity_1_rounded,
};

const Map<String, IconData> _categoryIcons = {
  // Emotions
  'sadness_and_distress': Icons.water_drop_rounded,
  'feeling_lost_and_seeking_guidance': Icons.explore_rounded,
  'anxiety_and_overthinking': Icons.psychology_rounded,
  'fear_of_the_future': Icons.foggy,
  'loneliness_and_feeling_unseen': Icons.person_outline_rounded,
  'despair_and_loss_of_hope': Icons.wb_twilight_rounded,
  'regret_and_missed_opportunities': Icons.history_rounded,
  'bereavement_and_calamity': Icons.heart_broken_rounded,
  // Faith and worship
  'repentance_and_returning_to_allah': Icons.volunteer_activism_rounded,
  'strengthening_faith_and_certainty': Icons.eco_rounded,
  'hardness_of_heart_and_lack_of_humility': Icons.ac_unit_rounded,
  'spiritual_fatigue_and_renewing_worship': Icons.battery_charging_full_rounded,
  'supplication_and_waiting': Icons.hourglass_top_rounded,
  'resisting_temptation_and_leaving_sin': Icons.shield_rounded,
  'meaning_and_purpose_of_life': Icons.auto_awesome_rounded,
  'seeking_refuge_from_whispers_and_evil': Icons.health_and_safety_rounded,
  // Hardships and decisions
  'enduring_trials_with_patience': Icons.terrain_rounded,
  'injustice_and_oppression': Icons.balance_rounded,
  'betrayal_by_someone_close': Icons.link_off_rounded,
  'anger_and_the_urge_to_retaliate': Icons.local_fire_department_rounded,
  'financial_hardship_and_worry': Icons.account_balance_wallet_rounded,
  'uncertainty_about_an_important_decision': Icons.alt_route_rounded,
  'not_understanding_what_happened': Icons.help_center_rounded,
  'illness_and_pain': Icons.healing_rounded,
  // Relationships and character
  'improving_marital_relationships': Icons.favorite_border_rounded,
  'strained_relationship_with_parents': Icons.family_restroom_rounded,
  'raising_children_and_family_wellbeing': Icons.child_care_rounded,
  'choosing_good_company': Icons.groups_rounded,
  'comparison_and_envy': Icons.compare_arrows_rounded,
  'avoiding_suspicion_backbiting_and_hurtful_speech': Icons.voice_over_off_rounded,
  'gratitude_for_blessings_and_success': Icons.star_rounded,
  'worldly_attachment_and_remembering_the_hereafter': Icons.hourglass_bottom_rounded,
};

const _fallback = Icons.auto_awesome_rounded;

IconData sectionIcon(String sectionId) => _sectionIcons[sectionId] ?? _fallback;

IconData categoryIcon(MoodCategory category) =>
    _categoryIcons[category.id] ?? sectionIcon(category.sectionId);
