import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:smart_travel/domain/params/RegisterParams.dart';
import 'package:smart_travel/core/services/image_upload_service.dart';
import 'package:smart_travel/injection_container.dart' as di;
import 'package:smart_travel/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_travel/presentation/blocs/auth/auth_event.dart';
import 'package:smart_travel/presentation/blocs/auth/auth_state.dart';
import 'package:smart_travel/presentation/widgets/common/custom_button.dart';
import 'package:smart_travel/presentation/widgets/common/custom_textfield.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _idCardController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isHost = false;
  // Files selected locally (deferred upload until register)
  File? _portraitFile;
  File? _idCardFile;
  File? _ownershipFile;

  // Uploaded URLs (populated when pressing register)
  String? _portraitUrl;
  String? _idCardImageUrl;
  String? _ownershipDocUrl;
  bool _isUploadingDoc = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng đồng ý với điều khoản dịch vụ')),
        );
        return;
      }
      // If host, ensure required files are selected and upload selected files first (deferred upload)
      Future<void> doRegister() async {
        try {
          if (_isHost) {
            if (_portraitFile == null || _idCardFile == null || _ownershipFile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng chọn ảnh chân dung, ảnh CCCD và giấy tờ sở hữu trước khi đăng ký.')),
              );
              return;
            }
            setState(() {
              _isUploadingDoc = true;
            });
            final imageUploadService = di.sl<ImageUploadService>();
            // Upload portrait
            if (_portraitFile != null) {
              _portraitUrl = await imageUploadService.uploadAvatar(_portraitFile!);
            }
            // Upload id card image
            if (_idCardFile != null) {
              _idCardImageUrl = await imageUploadService.uploadAvatar(_idCardFile!);
            }
            // Upload ownership document
            if (_ownershipFile != null) {
              _ownershipDocUrl = await imageUploadService.uploadAvatar(_ownershipFile!);
            }
          }

          final request = RegisterParams(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            role: _isHost ? 'HOST' : 'USER',
            idCardNumber: _isHost ? _idCardController.text.trim() : null,
            idCardImageUrl: _isHost ? _idCardImageUrl : null,
            ownershipDocumentUrl: _isHost ? _ownershipDocUrl : null,
            portraitUrl: _isHost ? _portraitUrl : null,
          );

          // Dispatch event tới BLoC
          context.read<AuthBloc>().add(RegisterSubmitted(request));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload hoặc đăng ký thất bại: $e')),
          );
        } finally {
          setState(() {
            _isUploadingDoc = false;
          });
        }
      }

      doRegister();
    }
  }


  Future<File?> _pickDocumentLocal() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn file: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _pickPortrait() async {
    final f = await _pickDocumentLocal();
    if (f != null) setState(() => _portraitFile = f);
  }

  Future<void> _pickIdCard() async {
    final f = await _pickDocumentLocal();
    if (f != null) setState(() => _idCardFile = f);
  }

  Future<void> _pickOwnershipDoc() async {
    final f = await _pickDocumentLocal();
    if (f != null) setState(() => _ownershipFile = f);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            // Hiển thị dialog thành công
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Expanded(child: Text('Đăng ký thành công!')),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.response.message ?? ''),
                    const SizedBox(height: 16),
                    const Text(
                      'Chúng tôi đã gửi một email xác thực đến địa chỉ email của bạn. Vui lòng kiểm tra hộp thư và nhấn vào link xác thực.',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Đã hiểu'),
                  ),
                ],
              ),
            );
          } else if (state is AuthError) {
            // Hiển thị lỗi
            final snackBar =  SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.fixed,
              backgroundColor: Colors.transparent,
              content: AwesomeSnackbarContent(
                title: 'Lỗi',
                message: state.message,
                contentType: ContentType.failure,
              ),
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(snackBar);
          }
        },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        if (isLoading) {
          return Center(
            child: Lottie.asset(
              'assets/lottie/travel_is_fun.json',
              width: 200,
              height: 500,
              repeat: true,

            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Back Button
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Quay lại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Logo
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.9,
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.2,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            image: const DecorationImage(
                              image: AssetImage("assets/images/img_1.png"),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),

                        const SizedBox(height: 8),
                        const Text(
                          'Bắt đầu hành trình khám phá của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 32),

                              // Register Form Card - Lắng nghe BLoC State
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name
                                CustomTextField(
                                  label: 'Họ và tên',
                                  hintText: "Nhập họ và tên",
                                  controller: _fullNameController,
                                  prefixIcon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập họ tên';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Email
                                CustomTextField(
                                  label: "Email",
                                  hintText: "example@email.com",
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Phone
                                IntlPhoneField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Số điện thoại',
                                    hintText: 'Nhập số điện thoại',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialCountryCode: 'VN',
                                  disableLengthCheck: true,
                                  onChanged: (phone) {
                                    print(phone.completeNumber);
                                  },
                                  validator: (phone) {
                                    if (phone == null || phone.number.isEmpty) {
                                      return 'Vui lòng nhập số điện thoại';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Role selection: User or Host
                                const Text('Bạn là:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                                const SizedBox(height: 8),
                                ToggleButtons(
                                  isSelected: [!_isHost, _isHost],
                                  onPressed: (index) {
                                    setState(() {
                                      _isHost = index == 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  constraints: const BoxConstraints(minHeight: 44, minWidth: 130),
                                  children: const [
                                    Text('Khách'),
                                    Text('Chủ homestay'),
                                  ],
                                ),

                                if (_isHost) ...[
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    label: 'Số CCCD/CMND',
                                    hintText: 'Nhập số CCCD/CMND',
                                    controller: _idCardController,
                                    prefixIcon: Icons.badge_outlined,
                                    validator: (value) {
                                      if (_isHost && (value == null || value.isEmpty)) {
                                        return 'Vui lòng nhập số CCCD';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Portrait uploader (pick local file, upload on submit)
                                  Text('Ảnh chân dung', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _isUploadingDoc ? null : _pickPortrait,
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: _portraitFile != null
                                          ? FileImage(_portraitFile!) as ImageProvider?
                                          : (_portraitUrl != null ? NetworkImage(_portraitUrl!) : null),
                                      child: _portraitFile == null && _portraitUrl == null
                                          ? const Icon(Icons.camera_alt, size: 32, color: Colors.grey)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Documents: ID image and ownership document
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _isUploadingDoc ? null : () async {
                                            await _pickIdCard();
                                          },
                                          icon: const Icon(Icons.upload_file),
                                          label: const Text('Upload ảnh CCCD'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _isUploadingDoc ? null : () async {
                                            await _pickOwnershipDoc();
                                          },
                                          icon: const Icon(Icons.upload_file),
                                          label: const Text('Upload sổ hộ khẩu/giấy tờ'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_idCardFile != null)
                                    SizedBox(height:80, child: Image.file(_idCardFile!, fit: BoxFit.contain)),
                                  if (_ownershipFile != null)
                                    SizedBox(height:80, child: Image.file(_ownershipFile!, fit: BoxFit.contain)),
                                  const SizedBox(height: 12),
                                ],
                                const SizedBox(height: 16),

                                // Password & Confirm Password
                                _buildPasswordField(
                                  label: 'Mật khẩu',
                                  controller: _passwordController,
                                  hint: 'Tối thiểu 8 ký tự',
                                  obscure: _obscurePassword,
                                  onToggle: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    if (value.length < 8) {
                                      return 'Mật khẩu phải có ít nhất 8 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                _buildPasswordField(
                                  label: 'Xác nhận mật khẩu',
                                  controller: _confirmPasswordController,
                                  hint: 'Nhập lại mật khẩu',
                                  obscure: _obscureConfirmPassword,
                                  onToggle: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng xác nhận mật khẩu';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Mật khẩu không khớp';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Terms & Conditions
                                Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _acceptTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _acceptTerms = value ?? false;
                                          });
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                          children: [
                                            TextSpan(text: 'Tôi đồng ý với '),
                                            TextSpan(
                                              text: 'Điều khoản dịch vụ',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(text: ' và '),
                                            TextSpan(
                                              text: 'Chính sách bảo mật',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Register Button
                                PrimaryButton(
                                  text: isLoading
                                      ? "Đang xử lý..."
                                      : "Đăng ký",
                                  onPressed: isLoading ? null : _handleRegister,
                                ),
                                const SizedBox(height: 24),

                                // Divider & Social Buttons
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: Colors.grey[300])),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        'Hoặc đăng ký với',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: Colors.grey[300])),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Login Link
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Đã có tài khoản? ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: const Text(
                                          'Đăng nhập',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}