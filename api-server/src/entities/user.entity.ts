import { Entity, Column, PrimaryColumn } from 'typeorm';

@Entity('User')
export class User {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 100 })
  email: string;

  @Column({ type: 'varchar', length: 100 })
  passwordHash: string;

  @Column({ type: 'varchar', length: 100 })
  salt: string;

  @Column({ type: 'datetime', precision: 3 })
  createdAt: Date;
}
