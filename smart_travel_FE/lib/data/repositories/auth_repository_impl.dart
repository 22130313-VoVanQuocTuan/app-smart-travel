import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_travel/core/error/exceptions.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/network/network_info.dart';
import 'package:smart_travel/data/data_sources/local/auth_local_data_source.dart';
import 'package:smart_travel/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:smart_travel/data/models/auth/facebook_login_request.dart';
import 'package:smart_travel/data/models/auth/google_login_request.dart';
import 'package:smart_travel/data/models/auth/login_request_modal.dart';
import 'package:smart_travel/data/models/auth/login_response_modal.dart';
import 'package:smart_travel/data/models/auth/refresh_token_request.dart';
import 'package:smart_travel/data/models/auth/register_request_model.dart';
import 'package:smart_travel/domain/entities/auth.dart';
import 'package:smart_travel/domain/params/RegisterParams.dart';
import 'package:smart_travel/domain/params/login_params.dart';
import 'package:smart_travel/domain/params/refresh_token_params.dart';
import 'package:smart_travel/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;
  final NetworkInfo networkInfo;
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final AuthLocalDataSource localDataSource;
  final FacebookAuth facebookAuth;



  AuthRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.localDataSource,
    required this.facebookAuth,
  });

  Future<void> _saveAuthSession(LoginResponseModal responseModel) async {
    await localDataSource.saveToken(responseModel.token);

    final userId = responseModel.userId;
    if (userId != null) {
      await localDataSource.saveUserId(userId);
    }

    final refreshToken = responseModel.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await localDataSource.saveRefreshToken(refreshToken);
    }

    final role = responseModel.role;
    if (role != null && role.isNotEmpty) {
      await localDataSource.saveRole(role);
    }

    final fullName = responseModel.fullName;
    if (fullName != null && fullName.isNotEmpty) {
      await localDataSource.saveFullName(fullName);
    }
  }


  @override
  Future<Either<Failure, AuthEntity>> register(
      RegisterParams params) async {
    // Kiểm tra kết nối mạng
    if (!await networkInfo.isConnected) {
      return const Left(
          NetworkFailure('Không có kết nối internet. Vui lòng kiểm tra lại.'));
    }

    try {
      final requestModal = RegisterRequestModel(
          fullName: params.fullName,
          email: params.email,
          phone: params.phone,
          password: params.password,
          confirmPassword: params.confirmPassword,
          role: params.role,
          idCardNumber: params.idCardNumber,
          idCardImageUrl: params.idCardImageUrl,
          ownershipDocumentUrl: params.ownershipDocumentUrl,
          portraitUrl: params.portraitUrl,
      );
      // Gọi remote data source
      final responseModel = await dataSource.register(requestModal);
      final entity = responseModel.toEntity();
      // Trả về kết quả thành công
      return Right(entity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Đã xảy ra lỗi không mong muốn: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login(LoginParams params) async {
    // TODO: implement login
    if(!await networkInfo.isConnected){
      return const Left(NetworkFailure('Không có kết nối internet. Vui lòng kiểm tra lại.'));
    }
    try{
      // Chuyển Domain → Data
      final requestModel = LoginRequestModal(
        email: params.email,
        password: params.password,
      );

      // Gọi remote data source
      final responseModel = await dataSource.login(requestModel);

      // Lưu token/refresh token sau khi login thành công
      await _saveAuthSession(responseModel);
      final entity = responseModel.toEntity();

      return  Right(entity);
    } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
    } catch (e) {
    return Left(ServerFailure('Đã xảy ra lỗi không mong muốn: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async{
    if(!await networkInfo.isConnected){
      return const Left(NetworkFailure('Không có kết nối internet. Vui lòng kiểm tra lại.'));
    }
    try{
      // Gọi remote data source
      final result = await dataSource.forgotPassword(email);
      return  Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Đã xảy ra lỗi không mong muốn: ${e.toString()}'));
    }
  }

  // ============ GOOGLE LOGIN METHOD ============
  @override
  Future<Either<Failure, AuthEntity>> googleLogin() async {
    // Kiểm tra kết nối mạng
    if (!await networkInfo.isConnected) {
      return const Left(
          NetworkFailure('Không có kết nối internet. Vui lòng kiểm tra lại.'));
    }

    try {
      //Google Sign In
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.authenticate();
      //Firebase Authentication
      final googleAuth = googleUser.authentication;
      final googleIdToken = googleAuth.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) {
        await googleSignIn.signOut();
        return const Left(ServerFailure('Khong lay duoc Google ID token!'));
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );
      final userCredential =
      await firebaseAuth.signInWithCredential(credential);
      //Lấy ID Token từ Firebase
      final idToken = await userCredential.user?.getIdToken() ?? '';
      //Chuẩn bị request model cho Spring Backend
      final requestModel = GoogleLoginRequest(
        idToken: idToken,
        email: googleUser.email,
        displayName: googleUser.displayName ?? '',
      );


      // Gửi tới Spring Backend qua Remote Data Source
      final responseModel = await dataSource.googleLogin(requestModel);

      // Lưu token, refresh token và thông tin user vào local storage
      await _saveAuthSession(responseModel);

      //Chuyển đổi Model  sang Entity
      final entity = responseModel.toEntity();

      return Right(entity);
    } on FirebaseAuthException catch (e) {
      // Firebase error
      await googleSignIn.signOut();
      return Left(ServerFailure('Firebase error: ${e.message}'));
    } on ServerException catch (e) {
      await googleSignIn.signOut();
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      await googleSignIn.signOut();
      return Left(NetworkFailure(e.message));
    } catch (e) {
      // Unexpected error
      await googleSignIn.signOut();
      return Left(ServerFailure('Google login failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> facebookLogin() async {
    // Kiểm tra kết nối mạng
    if (!await networkInfo.isConnected) {
      return const Left(
          NetworkFailure('Không có kết nối internet. Vui lòng kiểm tra lại.'));
    }

    try {
      // Facebook Sign In
      final loginResult = await facebookAuth.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.webOnly,
      );

      if (loginResult.status != LoginStatus.success) {
        return const Left(ServerFailure('Đăng nhập Facebook đã bị hủy hoặc thất bại!'));
      }

      // Lấy access token từ Facebook
      final accessToken = loginResult.accessToken!.tokenString;

      // Firebase Authentication
      final credential = FacebookAuthProvider.credential(accessToken);
      final userCredential = await firebaseAuth.signInWithCredential(credential);

      // Lấy thông tin user từ Firebase
      final user = userCredential.user;
      if (user == null) {
        await facebookAuth.logOut();
        return const Left(ServerFailure('Không lấy được thông tin người dùng từ Firebase!'));
      }

      // Lấy ID Token từ Firebase
      final idToken = await user.getIdToken() ?? '';

      // Lấy thông tin người dùng từ Facebook (nếu cần thêm thông tin)
      final userData = await facebookAuth.getUserData(fields: 'email,name');

      // Chuẩn bị request model cho Spring Backend
      final requestModel = FacebookLoginRequest(
        idToken: idToken,
        email: userData['email'] ?? user.email ?? '',
        displayName: userData['name'] ?? user.displayName ?? '',
      );

      // Gửi tới Spring Backend qua Remote Data Source
      final responseModel = await dataSource.facebookLogin(requestModel);

      // Lưu token, refresh token và thông tin user vào local storage
      await _saveAuthSession(responseModel);

      // Chuyển đổi Model sang Entity
      final entity = responseModel.toEntity();

      return Right(entity);
    } on FirebaseAuthException catch (e) {
      // Firebase error
      await facebookAuth.logOut();
      return Left(ServerFailure('Firebase error: ${e.message}'));
    } on ServerException catch (e) {
      await facebookAuth.logOut();
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      await facebookAuth.logOut();
      return Left(NetworkFailure(e.message));
    } catch (e) {
      // Unexpected error
      await facebookAuth.logOut();
      return Left(ServerFailure('Đăng nhập Facebook thất bại: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> refreshToken(RefreshTokenParams refreshToken) async{
    if(!await networkInfo.isConnected){
      return const Left(NetworkFailure('Không có kết nối internet. Vui lòng kiểm tra lại.'));
    }

    try {
      // Chuyển Domain → Data
      final requestModel = RefreshTokenRequest(
        refreshToken: refreshToken.refreshToken,
      );
      final loginResponse = await dataSource.refreshToken(requestModel);

      // Lưu lại access token; nếu BE có trả refresh token mới thì cập nhật luôn
      await _saveAuthSession(loginResponse);

      final entity = loginResponse.toEntity();
      return right(entity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Đã xảy ra lỗi không mong muốn: ${e.toString()}'));
    }
  }
}
