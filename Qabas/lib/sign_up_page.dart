// lib/sign_up_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';
import 'sign_in_page.dart';

/// ألوان قَبَس
class QabasColors {
  static const primary     = Color(0xFF0E3A2C); // أخضر داكن
  static const primaryMid  = Color(0xFF2F5145); // أخضر متوسط
  static const background  = Color(0xFFF7F8F7);
  static const onDark      = Colors.white;
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // ——— متغيرات تصميم سهلة التعديل ———
  static const double kTopSpacer     = 110; // نزّل/ارفع الفورم
  static const double kFieldGap      = 20;  // المسافة بين الحقول
  static const double kAvatarRadius  = 67;  // حجم الأفتار
  static const double kBgShiftUp     = 0;   // رفع الخلفية (px)
  static const double kAvatarYOffset = 0;   // تحريك الأفتار عموديًا
  // ————————————————————————————————

  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _pass2Ctrl    = TextEditingController();

  bool _loading = false;

  // صورة أفتار اختيارية (عرض فقط الآن)
  final ImagePicker _picker = ImagePicker();
  XFile? _avatarFile;
  Future<void> _pickAvatar() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (x != null) setState(() => _avatarFile = x);
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ======================= منطق التسجيل (كما هو) =======================
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final username      = _usernameCtrl.text.trim();
    final usernameLower = username.toLowerCase();
    final email         = _emailCtrl.text.trim();
    final pass          = _passCtrl.text;

    setState(() => _loading = true);

    try {
      // 1) فحص تكرار اسم المستخدم
      final exists = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLower', isEqualTo: usernameLower)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));

      if (exists.docs.isNotEmpty) {
        _snack('اسم المستخدم مستخدم مسبقًا. جرّبي اسمًا آخر.', color: Colors.red);
        return;
      }

      // 2) إنشاء الحساب
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final uid = cred.user!.uid;

      // 3) حفظ البيانات (بدون رفع صورة الآن)
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'username': username,
          'usernameLower': usernameLower,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        _snack('تم إنشاء الحساب، وتأخر حفظ البيانات… نكمل.', color: Colors.orange);
      } catch (_) {
        _snack('تم إنشاء الحساب، وتعذّر حفظ البيانات… نكمل.', color: Colors.orange);
      }

      _snack('تم تسجيلك بنجاح ', color: Colors.green);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ غير متوقع.';
      switch (e.code) {
        case 'email-already-in-use': msg = 'البريد مستخدم مسبقًا.'; break;
        case 'invalid-email':        msg = 'صيغة البريد غير صحيحة.'; break;
        case 'weak-password':        msg = 'كلمة المرور ضعيفة (على الأقل 6 أحرف).'; break;
      }
      _snack(msg, color: Colors.red);
    } catch (e) {
      _snack('تعذّر إنشاء الحساب: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: null, // بدون AppBar — نرسم الخلفية والسهم يدويًا
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 1) الخلفية (مع إمكانية رفعها)
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(0, -kBgShiftUp),
                child: Image.asset(
                  'assets/images/signUP-Background.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 2) المحتوى القابل للتمرير
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  children: [
                    const SizedBox(height: kTopSpacer),

                    // === الأفتار (اختياري) ===
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Transform.translate(
                        offset: const Offset(0, kAvatarYOffset),
                        child: Stack(
                          alignment: Alignment.bottomRight, // علامة + يمين
                          children: [
                            CircleAvatar(
                              radius: kAvatarRadius,
                              backgroundColor: QabasColors.primary,
                              foregroundImage: _avatarFile != null
                                  ? FileImage(File(_avatarFile!.path))
                                  : null,
                              child: _avatarFile == null
                                  ? const Icon(Icons.person, size: 56, color: Colors.white70)
                                  : null,
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 6, right: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.add, size: 18, color: QabasColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // الحقول (شفافة فوق الخلفية)
                    _FormFields(
                      formKey: _formKey,
                      usernameCtrl: _usernameCtrl,
                      emailCtrl: _emailCtrl,
                      passCtrl: _passCtrl,
                      pass2Ctrl: _pass2Ctrl,
                      loading: _loading,
                      onSubmit: _signUp,
                      gap: kFieldGap,
                    ),

                    const SizedBox(height: 22),

                    // زر التسجيل
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QabasColors.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _loading ? null : _signUp,
                        child: _loading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('تسجيل'),
                      ),
                    ),

                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInPage()),
                        );
                      },
                      child: const Text(
                        'لديك حساب مسبقًا؟ اضغط هنا',
                        style: TextStyle(
                          color: QabasColors.primaryMid,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3) زر الرجوع — آخر عنصر في الـ Stack ليكون فوق الكل وينضغط
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8, top: 4),
                  child: IconButton(
                    tooltip: 'رجوع',
                    splashRadius: 24,
                    // نثبت اتجاه الأيقونة لليمين (مثل صفحة تسجيل الدخول)
                    icon: const Directionality(
                      textDirection: TextDirection.ltr,
                      child: Icon(Icons.arrow_forward,
                          color: QabasColors.primary, size: 26),
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حقول النموذج (بدون خلفية)
class _FormFields extends StatelessWidget {
  const _FormFields({
    required GlobalKey<FormState> formKey,
    required TextEditingController usernameCtrl,
    required TextEditingController emailCtrl,
    required TextEditingController passCtrl,
    required TextEditingController pass2Ctrl,
    required bool loading,
    required Future<void> Function() onSubmit,
    this.gap = 14,
    super.key,
  })  : _formKey = formKey,
        _usernameCtrl = usernameCtrl,
        _emailCtrl = emailCtrl,
        _passCtrl = passCtrl,
        _pass2Ctrl = pass2Ctrl,
        _loading = loading,
        _onSubmit = onSubmit;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _usernameCtrl;
  final TextEditingController _emailCtrl;
  final TextEditingController _passCtrl;
  final TextEditingController _pass2Ctrl;
  final bool _loading;
  final Future<void> Function() _onSubmit;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final InputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide:
      BorderSide(color: QabasColors.primary.withOpacity(.35), width: 1.1),
    );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameCtrl,
            decoration: InputDecoration(
              labelText: 'اسم المستخدم',
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide:
                const BorderSide(color: QabasColors.primary, width: 1.4),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'أدخل اسم المستخدم';
              if (t.length < 3) return 'اسم المستخدم قصير جدًا';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: gap),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide:
                const BorderSide(color: QabasColors.primary, width: 1.4),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              final email = v?.trim() ?? '';
              final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!re.hasMatch(email)) return 'أدخل بريدًا صحيحًا';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: gap),
          TextFormField(
            controller: _passCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide:
                const BorderSide(color: QabasColors.primary, width: 1.4),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) => (v ?? '').length < 6 ? 'أقل شيء 6 أحرف' : null,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: gap),
          TextFormField(
            controller: _pass2Ctrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide:
                const BorderSide(color: QabasColors.primary, width: 1.4),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) => v != _passCtrl.text ? 'غير مطابقة' : null,
            onFieldSubmitted: (_) => _onSubmit(),
          ),
        ],
      ),
    );
  }
}
