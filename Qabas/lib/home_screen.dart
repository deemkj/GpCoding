import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ===== تحكم سريع بمكان الخلفية =====
  // قيمة سالبة ترفع الصورة للأعلى، موجبة تنزلها للأسفل (بالبكسل).
  static const double kBgShiftY = 10;
  // لو حبيتي تكبير/تصغير الخلفية:
  static const double kBgScale  = 1.0;
  // ===================================

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تأكيد تسجيل الخروج',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('هل تريد تسجيل الخروج؟',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('تأكيد'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      await _logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // نخلي المحتوى خلف شريط التطبيق لأن شفاف
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: null,                        // لا عنوان
          backgroundColor: Colors.transparent, // شفاف
          elevation: 0,
          foregroundColor: const Color(0xFF0E3A2C),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // الخلفية — عدلي kBgShiftY و kBgScale فوق
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(0, kBgShiftY),
                child: Transform.scale(
                  scale: kBgScale,
                  child: Image.asset(
                    'assets/images/homescreen.jpg', // تأكدي من المسار في pubspec.yaml
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),

            // Container(color: Colors.white.withOpacity(0.02)),
          ],
        ),
      ),
    );
  }
}
