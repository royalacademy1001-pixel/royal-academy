// 🔥 ADMIN NAVIGATION CONTROL (ULTRA PRO MAX)

import 'package:flutter/material.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class AdminNavigationControlPage extends StatefulWidget {
  const AdminNavigationControlPage({super.key});

  @override
  State<AdminNavigationControlPage> createState() =>
      _AdminNavigationControlPageState();
}

class _AdminNavigationControlPageState
    extends State<AdminNavigationControlPage> {

  List<Map<String, dynamic>> items = [];

  bool loading = true;

  final titleController = TextEditingController();
  final idController = TextEditingController();
  final iconController = TextEditingController();

  int order = 1;

  Set<String> roles = {"all"};

  bool saving = false;

  String selectedPageId = "home";

  final List<Map<String, dynamic>> availablePages = [
    {
      "id": "home",
      "title": "الرئيسية",
      "icon": "home",
      "roles": ["all"],
    },
    {
      "id": "courses",
      "title": "الكورسات",
      "icon": "courses",
      "roles": ["all"],
    },
    {
      "id": "payment",
      "title": "الدفع",
      "icon": "payment",
      "roles": ["all"],
    },
    {
      "id": "profile",
      "title": "حسابي",
      "icon": "profile",
      "roles": ["all"],
    },
    {
      "id": "instructor",
      "title": "لوحة المدرس",
      "icon": "instructor",
      "roles": ["instructor"],
    },
    {
      "id": "admin_payments",
      "title": "المدفوعات",
      "icon": "payment",
      "roles": ["admin"],
    },
    {
      "id": "admin_requests",
      "title": "طلبات المدرسين",
      "icon": "users",
      "roles": ["admin"],
    },
    {
      "id": "admin_analytics",
      "title": "Analytics",
      "icon": "analytics",
      "roles": ["admin"],
    },
    {
      "id": "admin_users",
      "title": "المستخدمين",
      "icon": "users",
      "roles": ["admin"],
    },
    {
      "id": "admin_nav_control",
      "title": "التحكم في البار",
      "icon": "settings",
      "roles": ["admin"],
    },
    {
      "id": "admin_courses",
      "title": "إدارة الكورسات",
      "icon": "courses",
      "roles": ["admin"],
    },
    {
      "id": "admin_categories",
      "title": "إدارة التصنيفات",
      "icon": "categories",
      "roles": ["admin"],
    },
    {
      "id": "admin_notifications",
      "title": "الإشعارات",
      "icon": "notifications",
      "roles": ["admin"],
    },
    {
      "id": "admin_students",
      "title": "إدارة الطلاب",
      "icon": "users",
      "roles": ["admin"],
    },
    {
      "id": "admin_news",
      "title": "إدارة الأخبار",
      "icon": "news",
      "roles": ["admin"],
    },
  ];

  final List<Map<String, dynamic>> fallbackNav = [
    {
      "id": "home",
      "title": "الرئيسية",
      "icon": "home",
      "order": 1,
      "roles": ["all"],
      "enabled": true,
    },
    {
      "id": "courses",
      "title": "الكورسات",
      "icon": "courses",
      "order": 2,
      "roles": ["all"],
      "enabled": true,
    },
    {
      "id": "payment",
      "title": "الدفع",
      "icon": "payment",
      "order": 3,
      "roles": ["all"],
      "enabled": true,
    },
    {
      "id": "profile",
      "title": "حسابي",
      "icon": "profile",
      "order": 4,
      "roles": ["all"],
      "enabled": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    listenData();
    _applyTemplate(selectedPageId);
  }

  @override
  void dispose() {
    titleController.dispose();
    idController.dispose();
    iconController.dispose();
    super.dispose();
  }

  void _applyTemplate(String pageId) {
    selectedPageId = pageId;

    final existing = items.where((e) => e['id'] == pageId).toList();
    final template = availablePages.firstWhere(
      (e) => e['id'] == pageId,
      orElse: () => {
        "id": pageId,
        "title": pageId,
        "icon": "settings",
        "roles": ["all"],
      },
    );

    if (existing.isNotEmpty) {
      final item = existing.first;
      idController.text = (item['id'] ?? template['id']).toString();
      titleController.text = (item['title'] ?? template['title']).toString();
      iconController.text = (item['icon'] ?? template['icon']).toString();

      final rawRoles = item['roles'] ?? template['roles'] ?? ["all"];
      roles = rawRoles is List
          ? rawRoles.map((e) => e.toString()).toSet()
          : {"all"};

      order = item['order'] is int
          ? item['order']
          : int.tryParse(item['order']?.toString() ?? "") ?? items.length + 1;
    } else {
      idController.text = template['id'].toString();
      titleController.text = template['title'].toString();
      iconController.text = template['icon'].toString();

      final rawRoles = template['roles'] ?? ["all"];
      roles = rawRoles is List
          ? rawRoles.map((e) => e.toString()).toSet()
          : {"all"};

      order = items.length + 1;
    }

    setState(() {});
  }

  void listenData() {
    FirebaseService.firestore
        .collection("app_settings")
        .doc("navigation")
        .snapshots()
        .listen((doc) async {

      final data = doc.data();

      if (data == null || data['items'] == null) {
        items = List.from(fallbackNav);

        await FirebaseService.firestore
            .collection("app_settings")
            .doc("navigation")
            .set({
          "items": items,
        });

        if (mounted) {
          _applyTemplate(selectedPageId);
          setState(() => loading = false);
        }
        return;
      }

      List raw = data['items'];

      if (raw.isEmpty) {
        items = List.from(fallbackNav);

        await FirebaseService.firestore
            .collection("app_settings")
            .doc("navigation")
            .set({
          "items": items,
        });

        if (mounted) {
          _applyTemplate(selectedPageId);
          setState(() => loading = false);
        }
        return;
      }

      raw = raw.where((e) => (e['enabled'] ?? true) == true).toList();

      if (raw.isEmpty) {
        items = List.from(fallbackNav);

        await FirebaseService.firestore
            .collection("app_settings")
            .doc("navigation")
            .set({
          "items": items,
        });

        if (mounted) {
          _applyTemplate(selectedPageId);
          setState(() => loading = false);
        }
        return;
      }

      raw.sort((a, b) =>
          (a['order'] ?? 0).compareTo(b['order'] ?? 0));

      items = raw.cast<Map<String, dynamic>>();

      if (mounted) {
        _applyTemplate(selectedPageId);
        setState(() => loading = false);
      }
    }, onError: (e) {
      items = List.from(fallbackNav);
      if (mounted) {
        _applyTemplate(selectedPageId);
        setState(() => loading = false);
      }
    });
  }

  Future saveAll() async {
    saving = true;
    setState(() {});

    final sortedItems = List<Map<String, dynamic>>.from(items);
    sortedItems.sort((a, b) {
      final aOrder = a['order'] is int ? a['order'] : int.tryParse(a['order'].toString()) ?? 0;
      final bOrder = b['order'] is int ? b['order'] : int.tryParse(b['order'].toString()) ?? 0;
      return aOrder.compareTo(bOrder);
    });

    await FirebaseService.firestore
        .collection("app_settings")
        .doc("navigation")
        .set({
      "items": sortedItems,
    });

    saving = false;
    setState(() {});
  }

  void addItem() {
    if (idController.text.trim().isEmpty) return;

    final index = items.indexWhere((e) => e['id'] == idController.text.trim());

    final data = {
      "id": idController.text.trim(),
      "title": titleController.text.trim(),
      "icon": iconController.text.trim(),
      "order": order,
      "roles": roles.toList(),
      "enabled": true,
    };

    if (index != -1) {
      items[index] = data;
    } else {
      items.add(data);
    }

    clearForm();
    saveAll();
    setState(() {});
  }

  void clearForm() {
    titleController.clear();
    idController.clear();
    iconController.clear();
    order = items.length + 1;
    roles = {"all"};
    selectedPageId = "home";
  }

  void deleteItem(int index) {
    items.removeAt(index);
    saveAll();
    setState(() {});
  }

  void toggleRole(String role) {
    if (roles.contains(role)) {
      roles.remove(role);
    } else {
      roles.add(role);
    }
    setState(() {});
  }

  void updateOrder(int index, int newOrder) {
    items[index]['order'] = newOrder;
    saveAll();
    setState(() {});
  }

  void updateField(int index, String key, dynamic value) {
    items[index][key] = value;
    saveAll();
    setState(() {});
  }

  void toggleEnabled(int index) {
    items[index]['enabled'] =
        !(items[index]['enabled'] ?? true);
    saveAll();
    setState(() {});
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    for (int i = 0; i < items.length; i++) {
      items[i]['order'] = i + 1;
    }

    saveAll();
    setState(() {});
  }

  Widget _pageSelector() {
    return DropdownButtonFormField<String>(
      value: selectedPageId,
      dropdownColor: AppColors.black,
      decoration: InputDecoration(
        labelText: "اختار الصفحة",
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      items: availablePages.map((page) {
        return DropdownMenuItem<String>(
          value: page['id'].toString(),
          child: Text(
            page['title'].toString(),
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        _applyTemplate(value);
      },
    );
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    final temp = items[index - 1];
    items[index - 1] = items[index];
    items[index] = temp;
    for (int i = 0; i < items.length; i++) {
      items[i]['order'] = i + 1;
    }
    saveAll();
    setState(() {});
  }

  void _moveDown(int index) {
    if (index >= items.length - 1) return;
    final temp = items[index + 1];
    items[index + 1] = items[index];
    items[index] = temp;
    for (int i = 0; i < items.length; i++) {
      items[i]['order'] = i + 1;
    }
    saveAll();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("⚙️ التحكم في الناف بار",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
        actions: [
          if (saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 2),
              ),
            )
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text("No Data"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [

                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: AppColors.premiumCard,
                        child: Column(
                          children: [

                            _pageSelector(),

                            const SizedBox(height: 10),

                            TextField(
                              controller: idController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  hintText: "id (home, courses...)"),
                              onChanged: (v) {
                                final found = availablePages.where((e) => e['id'] == v.trim()).toList();
                                if (found.isNotEmpty && titleController.text.isEmpty) {
                                  titleController.text = found.first['title'].toString();
                                  iconController.text = found.first['icon'].toString();
                                }
                              },
                            ),

                            TextField(
                              controller: titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  hintText: "title"),
                            ),

                            TextField(
                              controller: iconController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  hintText: "icon name"),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                roleChip("all"),
                                roleChip("admin"),
                                roleChip("instructor"),
                                roleChip("vip"),
                                roleChip("user"),
                              ],
                            ),

                            const SizedBox(height: 10),

                            ElevatedButton(
                              style: AppColors.goldButton,
                              onPressed: addItem,
                              child: const Text("➕ إضافة"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: reorder,
                        children: items.asMap().entries.map((entry) {

                          int index = entry.key;
                          var item = entry.value;

                          final isHome = (item['id'] ?? "").toString() == "home";

                          return Container(
                            key: ValueKey("${item['id']}_$index"),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: AppColors.premiumCard,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(item['title'] ?? "",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    if (!isHome)
                                      Switch(
                                        value: item['enabled'] ?? true,
                                        onChanged: (_) =>
                                            toggleEnabled(index),
                                      )
                                    else
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Icon(Icons.lock, color: Colors.green),
                                      ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(
                                        Icons.drag_handle,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                TextField(
                                  controller: TextEditingController(
                                      text: item['title']),
                                  onChanged: (v) =>
                                      updateField(index, "title", v),
                                  style: const TextStyle(color: Colors.white),
                                ),

                                TextField(
                                  controller: TextEditingController(
                                      text: item['icon']),
                                  onChanged: (v) =>
                                      updateField(index, "icon", v),
                                  style: const TextStyle(color: Colors.white),
                                ),

                                TextField(
                                  controller: TextEditingController(
                                      text: item['order'].toString()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => updateOrder(
                                      index,
                                      int.tryParse(v) ?? 0),
                                  style: const TextStyle(color: Colors.white),
                                ),

                                const SizedBox(height: 10),

                                Wrap(
                                  spacing: 5,
                                  children: ["all","admin","instructor","vip","user"]
                                      .map((r) => FilterChip(
                                            label: Text(r),
                                            selected:
                                                (item['roles'] ?? [])
                                                    .contains(r),
                                            onSelected: (_) {
                                              List list =
                                                  item['roles'] ?? [];

                                              if (list.contains(r)) {
                                                list.remove(r);
                                              } else {
                                                list.add(r);
                                              }

                                              updateField(
                                                  index, "roles", list);
                                            },
                                          ))
                                      .toList(),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                                      onPressed: () => _moveUp(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                      onPressed: () => _moveDown(index),
                                    ),
                                    if (!isHome)
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => deleteItem(index),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget roleChip(String role) {
    bool selected = roles.contains(role);

    return GestureDetector(
      onTap: () => toggleRole(role),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          role,
          style: TextStyle(
              color: selected ? Colors.black : Colors.white),
        ),
      ),
    );
  }
}