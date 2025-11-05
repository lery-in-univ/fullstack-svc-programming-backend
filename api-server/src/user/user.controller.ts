import { Body, Controller, Post } from '@nestjs/common';
import { UserService } from './user.service';
import { LoginResponseDto } from './dto/LoginResponseDto';
import { LoginRequestDto } from './dto/LoginRequestDto';
import { RegisterRequestDto } from './dto/RegisterRequestDto';
import { RegisterResponseDto } from './dto/RegisterResponseDto';

@Controller()
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post('/login')
  async login(@Body() dto: LoginRequestDto): Promise<LoginResponseDto> {
    const { email, password } = dto;
    const token = await this.userService.login(email, password);
    return { token };
  }

  @Post('/users')
  async register(
    @Body() dto: RegisterRequestDto,
  ): Promise<RegisterResponseDto> {
    const { email, password } = dto;
    const user = await this.userService.register(email, password);
    return { id: user.id, email: user.email, createdAt: user.createdAt };
  }
}
