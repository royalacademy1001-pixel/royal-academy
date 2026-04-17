part of 'users_page.dart';

extension UsersWidgets on _UsersPageState {
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final selected = filterMode == value;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        setState(() => filterMode = value);
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? Colors.black : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.black.withValues(alpha: 0.45),
      side: BorderSide(
        color: selected
            ? AppColors.gold
            : Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection(List<Map<String, dynamic>> users) {
    final total = users.length;
    final vip = users.where(UsersLogic.isVip).length;
    final blocked = users.where(UsersLogic.isBlocked).length;
    final linked = users.where(UsersLogic.isLinked).length;
    final subscribed = users.where(UsersLogic.isSubscribed).length;
    final admins = users.where(UsersLogic.isAdminUser).length;
    final instructors = users.where(UsersLogic.isInstructor).length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statCard("الإجمالي", total.toString(), Icons.groups, Colors.white),
        _statCard("VIP", vip.toString(), Icons.star, AppColors.gold),
        _statCard("محظورين", blocked.toString(), Icons.block, Colors.redAccent),
        _statCard("مربوطين", linked.toString(), Icons.link, Colors.green),
        _statCard("مشتركين", subscribed.toString(), Icons.verified, Colors.blue),
        _statCard("Admin", admins.toString(), Icons.admin_panel_settings, Colors.orange),
        _statCard("مدرسين", instructors.toString(), Icons.school, Colors.purple),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "ابحث بالاسم أو الإيميل أو الهاتف أو Student ID...",
              prefixIcon: const Icon(Icons.search, color: AppColors.gold, size: 18),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () {
                        searchController.clear();
                        setState(() => search = "");
                      },
                    ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => search = v),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip("all", "الكل", Icons.people),
                const SizedBox(width: 6),
                _filterChip("vip", "VIP فقط", Icons.star),
                const SizedBox(width: 6),
                _filterChip("subscribed", "مشترك", Icons.verified),
                const SizedBox(width: 6),
                _filterChip("linked", "مربوط", Icons.link),
                const SizedBox(width: 6),
                _filterChip("unlinked", "غير مربوط", Icons.link_off),
                const SizedBox(width: 6),
                _filterChip("blocked", "محظور", Icons.block),
                const SizedBox(width: 6),
                _filterChip("admins", "Admins", Icons.admin_panel_settings),
                const SizedBox(width: 6),
                _filterChip("instructors", "مدرسين", Icons.school),
                const SizedBox(width: 6),
                _filterChip("requests", "طلبات المدرسين", Icons.pending_actions),
                const SizedBox(width: 6),
                _filterChip("students", "طلاب فقط", Icons.person),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.star, color: AppColors.gold, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "لوحة تحكم المستخدمين كاملة: VIP / Admin / Instructor / Courses / Results / Attendance / Link / Block",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
    );
  }

  Widget _emptyView(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 280,
          child: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorView(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 260,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "اسحب لتحديث الصفحة",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _unauthorizedView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            const Text(
              "🚫 غير مصرح بالدخول",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "هذه الصفحة مخصصة للمسؤولين فقط",
              style: TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              child: const Text("رجوع"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSelector() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "جاري تحميل الكورسات...",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Text(
              "❌ حدث خطأ في تحميل الكورسات",
              style: TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          );
        }

        final courses = snapshot.data ?? [];

        if (courses.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Text(
              "لا توجد كورسات متاحة",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          );
        }

        final ids = courses.map((e) => UsersLogic.text(e['_id'])).toSet();
        final selectedValue =
            selectedCourseId != null && ids.contains(selectedCourseId)
                ? selectedCourseId
                : null;

        if (selectedCourseId != null && !ids.contains(selectedCourseId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                selectedCourseId = null;
                selectedCourseTitle = "";
              });
            }
          });
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "اختيار كورس للتحكم في الصلاحيات",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedValue,
                dropdownColor: AppColors.black,
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "اختر كورس",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: courses.map((course) {
                  final id = UsersLogic.text(course['_id']);
                  final title = UsersLogic.text(course['title']).isEmpty
                      ? id
                      : UsersLogic.text(course['title']);
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  final title = UsersLogic.courseTitleById(courses, value);
                  setState(() {
                    selectedCourseId = value;
                    selectedCourseTitle = title;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _studentCard(
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final userId = UsersLogic.text(data['_id']);
    final name =
        UsersLogic.text(data['name']).isEmpty ? "Student" : UsersLogic.text(data['name']);
    final email = UsersLogic.text(data['email']);
    final phone = UsersLogic.text(data['phone']);
    final vip = UsersLogic.isVip(data);
    final blocked = UsersLogic.isBlocked(data);
    final linked = UsersLogic.isLinked(data);
    final subscribed = UsersLogic.isSubscribed(data);
    final isAdmin = UsersLogic.isAdminUser(data);
    final isInstructor = UsersLogic.isInstructor(data);
    final pendingInstructor = UsersLogic.hasPendingInstructorRequest(data);
    final isMe = userId == currentUserId;

    final studentId = UsersLogic.text(data['studentId']);
    final lastResultScore = UsersLogic.intValue(data['lastResultScore']);
    final lastAttendanceAt = UsersLogic.text(data['lastAttendanceAt']);
    final subscriptionEnd = UsersLogic.text(data['subscriptionEnd']);
    final role = UsersLogic.text(data['role']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vip
              ? AppColors.gold.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: vip
                    ? AppColors.gold.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                child: Text(
                  name.trim().isEmpty
                      ? "U"
                      : name.trim().substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: vip ? AppColors.gold : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    if (studentId.isNotEmpty)
                      Text(
                        "Student ID: $studentId",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.black,
                icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                onSelected: (value) async {
                  switch (value) {
                    case "edit":
                      await _editStudent(userId, data);
                      break;
                    case "subscription":
                      await _toggleSubscription(userId, subscribed, data);
                      break;
                    case "vip":
                      await _toggleVip(userId, vip, data);
                      break;
                    case "block":
                      if (await confirm(blocked ? "فك الحظر؟" : "حظر المستخدم؟")) {
                        await _toggleBlock(userId, blocked, data);
                      }
                      break;
                    case "admin":
                      if (!isMe &&
                          await confirm(
                            isAdmin ? "إزالة صفة Admin؟" : "جعل المستخدم Admin؟",
                          )) {
                        await _makeAdmin(userId, isAdmin, data);
                      }
                      break;
                    case "unlockCourse":
                      if (selectedCourseId != null &&
                          await confirm("فتح الكورس المحدد لهذا المستخدم؟")) {
                        await _unlockCourse(userId, data);
                      }
                      break;
                    case "lockCourse":
                      if (selectedCourseId != null &&
                          await confirm("قفل الكورس المحدد لهذا المستخدم؟")) {
                        await _lockCourse(userId, data);
                      }
                      break;
                    case "link":
                      await _linkStudent(userId, data);
                      break;
                    case "unlink":
                      if (await confirm("فصل الربط الحالي؟")) {
                        await _unlinkStudent(userId, data);
                      }
                      break;
                    case "attendance":
                      await _markAttendance(userId, data);
                      break;
                    case "result":
                      await _addResult(userId, data);
                      break;
                    case "approveInstructor":
                      await _approveInstructor(userId, data);
                      break;
                    case "rejectInstructor":
                      await _rejectInstructor(userId, data);
                      break;
                    case "removeInstructor":
                      await _removeInstructor(userId, data);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "edit",
                    child: Text("✏️ تعديل", style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: "subscription",
                    child: Text(
                      subscribed ? "💳 إلغاء الاشتراك" : "💳 تفعيل الاشتراك",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
                    value: "vip",
                    child: Text(
                      vip ? "⭐ إلغاء VIP" : "⭐ تفعيل VIP",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (!isMe)
                    PopupMenuItem(
                      value: "block",
                      child: Text(
                        blocked ? "✅ فك الحظر" : "🚫 حظر المستخدم",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (!isMe)
                    PopupMenuItem(
                      value: "admin",
                      child: Text(
                        isAdmin ? "❌ إزالة Admin" : "👑 جعل Admin",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (selectedCourseId != null) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: "unlockCourse",
                      child: Text(
                        "🔓 فتح الكورس المحدد",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: "lockCourse",
                      child: Text(
                        "🔒 قفل الكورس المحدد",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: "link",
                    child: Text(
                      linked ? "🔗 إعادة ربط طالب" : "🔗 ربط بطالب",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (linked)
                    const PopupMenuItem(
                      value: "unlink",
                      child: Text(
                        "🔗 فصل الربط",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: "attendance",
                    child: Text(
                      "✅ تسجيل حضور",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem(
                    value: "result",
                    child: Text(
                      "📊 إضافة نتيجة",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  if (pendingInstructor) const PopupMenuDivider(),
                  if (pendingInstructor)
                    const PopupMenuItem(
                      value: "approveInstructor",
                      child: Text(
                        "🎓 قبول كمدرس",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (pendingInstructor)
                    const PopupMenuItem(
                      value: "rejectInstructor",
                      child: Text(
                        "❌ رفض طلب المدرس",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (isInstructor)
                    const PopupMenuItem(
                      value: "removeInstructor",
                      child: Text(
                        "🚫 إلغاء صفة المدرس",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (vip) _badge("VIP", AppColors.gold),
              if (blocked) _badge("محظور", Colors.red),
              if (linked) _badge("مربوط", Colors.green),
              if (subscribed) _badge("مشترك", Colors.blue),
              if (isAdmin) _badge("Admin", Colors.orange),
              if (isInstructor) _badge("مدرس", Colors.purple),
              if (pendingInstructor) _badge("طلب مدرس", Colors.deepOrange),
              if (studentId.isNotEmpty) _badge("Student Linked", Colors.teal),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "آخر نتيجة: ${lastResultScore > 0 ? lastResultScore.toString() : "لا يوجد"}   |   آخر حضور: ${lastAttendanceAt.isNotEmpty ? lastAttendanceAt : "لا يوجد"}",
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          if (subscriptionEnd.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                "انتهاء الاشتراك: $subscriptionEnd",
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          if (role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                "Role: $role",
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _actionButton(
                label: vip ? "إلغاء VIP" : "تفعيل VIP",
                icon: Icons.star,
                color: vip ? Colors.amber : Colors.lightBlueAccent,
                onTap: () => _toggleVip(userId, vip, data),
              ),
              _actionButton(
                label: blocked ? "فك الحظر" : "حظر",
                icon: Icons.block,
                color: Colors.redAccent,
                onTap: () => _toggleBlock(userId, blocked, data),
              ),
              _actionButton(
                label: linked ? "فصل الربط" : "ربط طالب",
                icon: linked ? Icons.link_off : Icons.link,
                color: linked ? Colors.orange : Colors.green,
                onTap: () => linked
                    ? _unlinkStudent(userId, data)
                    : _linkStudent(userId, data),
              ),
              _actionButton(
                label: "تسجيل كورسات",
                icon: Icons.playlist_add,
                color: Colors.green,
                onTap: () => _unlockCourse(userId, data),
              ),
              _actionButton(
                label: "إضافة نتيجة",
                icon: Icons.grade,
                color: Colors.purple,
                onTap: () => _addResult(userId, data),
              ),
              _actionButton(
                label: "حضور",
                icon: Icons.check_circle,
                color: Colors.blue,
                onTap: () => _markAttendance(userId, data),
              ),
              _actionButton(
                label: "تعديل",
                icon: Icons.edit,
                color: Colors.grey,
                onTap: () => _editStudent(userId, data),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> users, String currentUserId) {
    final filteredUsers = UsersLogic.applyFilters(users, search, filterMode);

    Widget listBody;
    if (filteredUsers.isEmpty) {
      listBody = _emptyView("لا توجد بيانات مطابقة");
    } else {
      listBody = ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final data = filteredUsers[index];
          return _studentCard(data, currentUserId);
        },
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: _header(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildCourseSelector(),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _statsSection(users),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "عدد النتائج: ${filteredUsers.length}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.black,
                onRefresh: _refreshAll,
                child: listBody,
              ),
            ),
          ],
        ),
        if (loadingAction) _loadingOverlay(),
      ],
    );
  }
}