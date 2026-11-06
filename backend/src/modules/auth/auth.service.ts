import { authRepository } from './auth.repository';
import { AuthResponseData, LoginInput, PublicUser, RegisterInput } from './auth.types';
import { hashPassword, verifyPassword } from '../../utils/password.util';
import { generateToken } from '../../utils/jwt.util';
import { AppError } from '../../utils/response.util';

export class AuthService {
  /**
   * Mendaftarkan pengguna baru.
   * Memastikan email belum terdaftar, melakukan hash password dengan bcrypt,
   * dan menyimpan data pengguna ke database.
   */
  public async register(input: RegisterInput): Promise<AuthResponseData> {
    const existingUser = await authRepository.findByEmail(input.email);
    if (existingUser) {
      throw new AppError('Email sudah terdaftar', 409);
    }

    const passwordHash = await hashPassword(input.password);
    const newUser = await authRepository.createUser(
      input.username,
      input.email,
      passwordHash
    );

    const token = generateToken({
      id: newUser.id,
      username: newUser.username,
      email: newUser.email,
    });

    return {
      user: {
        id: newUser.id,
        username: newUser.username,
        email: newUser.email,
      },
      token,
    };
  }

  /**
   * Autentikasi login menggunakan email dan password.
   * Mengembalikan profil publik pengguna (tanpa password) beserta JWT token.
   */
  public async login(input: LoginInput): Promise<AuthResponseData> {
    const user = await authRepository.findByEmail(input.email);
    if (!user) {
      throw new AppError('Email atau password salah', 401);
    }

    const isPasswordValid = await verifyPassword(input.password, user.password);
    if (!isPasswordValid) {
      throw new AppError('Email atau password salah', 401);
    }

    const publicUser: PublicUser = {
      id: Number(user.id),
      username: user.username,
      email: user.email,
    };

    const token = generateToken({
      id: publicUser.id,
      username: publicUser.username,
      email: publicUser.email,
    });

    return {
      user: publicUser,
      token,
    };
  }

  /**
   * Mengambil profil pengguna yang sedang login berdasarkan ID dari JWT.
   */
  public async getCurrentUser(userId: number): Promise<PublicUser> {
    const user = await authRepository.findById(userId);
    if (!user) {
      throw new AppError('Pengguna tidak ditemukan', 404);
    }
    return user;
  }
}

export const authService = new AuthService();
