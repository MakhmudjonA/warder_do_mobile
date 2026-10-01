import 'package:equatable/equatable.dart';

/// Odatlarni papkalarga ajratish uchun guruh.
///
/// Odat guruhsiz ham bo'lishi mumkin (`habit.groupId == null`) — bunday
/// odatlar bosh ekranda alohida ajratilmaydi, oddiy ro'yxatda ko'rinadi.
class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.order,
  });

  final String id;
  final String name;

  /// Ikonka kaliti (`"morning"`), `HabitIcons.resolve` bilan chiziladi.
  final String icon;

  /// Hex rang (`"#5B6EF5"`).
  final String color;

  final int order;

  Group copyWith({String? name, String? icon, String? color, int? order}) {
    return Group(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, order];
}

/// Guruh shabloni — **butunlay client tomonda**.
///
/// Backend'da guruh shablonlari yo'q (`GET /templates` faqat odatlar uchun),
/// shuning uchun bu katalog ilova ichida turadi. Tanlanganda oddiygina
/// "Guruh qo'shish" formasini oldindan to'ldiradi.
class GroupTemplate extends Equatable {
  const GroupTemplate({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final String icon;
  final String color;

  @override
  List<Object?> get props => [name, icon, color];
}

/// Shablonlar ekranidagi bitta bo'lim ("Eng mashhur", "Kun vaqti"...).
class GroupTemplateSection extends Equatable {
  const GroupTemplateSection({required this.title, required this.templates});

  final String title;
  final List<GroupTemplate> templates;

  @override
  List<Object?> get props => [title, templates];
}
