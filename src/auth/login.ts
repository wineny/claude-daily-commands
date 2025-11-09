// TODO: Add proper error handling
export async function login(username: string, password: string) {
  // FIXME: Implement actual authentication logic
  console.log('Login attempt:', username);

  if (!username || !password) {
    throw new Error('Missing credentials');
  }

  // Mock implementation
  return { token: 'mock-token-123' };
}

// NOTE: This is a temporary implementation
