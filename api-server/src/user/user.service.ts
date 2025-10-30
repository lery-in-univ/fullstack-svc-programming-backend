import {
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { User } from 'src/entities/user.entity';
import { PasswordHashCreator } from 'src/util/password-hash-creator';
import { TokenManager } from 'src/util/token-manager';
import { DataSource, Repository } from 'typeorm';
import { ulid } from 'ulid';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    private readonly dataSource: DataSource,

    private readonly passwordHashCreator: PasswordHashCreator,
    private readonly tokenManager: TokenManager,
  ) {}

  async register(email: string, password: string): Promise<User> {
    return await this.dataSource.transaction(async (em) => {
      const userRepository = em.getRepository(User);

      const prevUser = await userRepository.findOneBy({ email });
      if (prevUser) {
        throw new UnprocessableEntityException(
          '이미 해당 이메일로 가입한 유저가 존재합니다.',
        );
      }

      const hashedPassword = this.passwordHashCreator.create(password);

      const newUser = userRepository.create({
        id: ulid(),
        email,
        passwordHash: hashedPassword.hash,
        salt: hashedPassword.salt,
        createdAt: new Date(),
      });
      await userRepository.save(newUser);

      return newUser;
    });
  }

  async login(email: string, password: string): Promise<string> {
    const user = await this.userRepository.findOneBy({ email });
    if (!user) {
      throw new NotFoundException('해당 유저는 존재하지 않습니다.');
    }

    const { passwordHash, salt } = user;
    this.passwordHashCreator.verify(password, { hash: passwordHash, salt });

    return this.tokenManager.create(user.id);
  }
}
