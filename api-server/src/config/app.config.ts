type AppConfig = {
  jwtSecret: string;
};

export const appConfig: AppConfig = {
  jwtSecret: process.env.JWT_SECRET || 'jwtSecret',
};
