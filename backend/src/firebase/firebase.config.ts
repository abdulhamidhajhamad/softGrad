import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class FirebaseConfig {
  constructor() {
    if (!admin.apps.length) {
      try {
        const serviceAccountPath = path.join(
          process.cwd(), 
          'src', 
          'firebase', 
          'weddingplanner-89486-firebase-adminsdk-fbsvc-789e102f65.json'
        );
        
        console.log('Looking for file at:', serviceAccountPath);
        
        const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
        
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          storageBucket: 'weddingplanner-89486.appspot.com'
        });
        
        console.log('✅ Firebase initialized successfully');
      } catch (error) {
        console.error('❌ Firebase initialization error:', error);
        throw error;
      }
    }
  }

  getStorage() {
    return admin.storage();
  }

  getFirestore() {
    return admin.firestore();
  }

  getAuth() {
    return admin.auth();
  }
}