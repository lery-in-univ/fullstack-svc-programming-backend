import crypto from 'crypto';
import { ForbiddenException, Injectable } from '@nestjs/common';

type HashedPassword = {
  hash: string;
  salt: string;
};

@Injectable()
export class PasswordHashCreator {
  create(password: string): HashedPassword {
    const newSalt = this.createSalt();
    const newHash = this.createHash(password, newSalt);

    return { hash: newHash, salt: newSalt };
  }

  verify(password: string, hashedPassword: HashedPassword): void {
    const hash = this.createHash(password, hashedPassword.salt);
    if (hash !== hashedPassword.hash) {
      throw new ForbiddenException('비밀번호가 일치하지 않습니다.');
    }
  }

  private createSalt(): string {
    return crypto.randomBytes(16).toString('hex');
  }

  private createHash(password: string, salt: string): string {
    return crypto.createHmac('sha256', salt).update(password).digest('hex');
  }
}
