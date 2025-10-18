import crypto from 'crypto';
export const signPayload = (p: string) => crypto.createHmac('sha256', process.env.APP_EXPORT_SECRET!).update(p).digest('hex');
export const verifySignature = (p: string, s: string) => signPayload(p) === s;
