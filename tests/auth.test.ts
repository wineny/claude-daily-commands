import { login } from '../src/auth/login';

describe('Authentication', () => {
  // TODO: Add more test cases
  it('should login successfully', async () => {
    const result = await login('user', 'pass');
    expect(result.token).toBeDefined();
  });

  // FIXME: Test failure cases
});
