import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';

@Injectable()
export class FirebaseConfig {
  constructor() {
    if (!admin.apps.length) {
      const serviceAccount = require('../../../weddingplanner-89486-firebase-adminsdk-fbsvc-789e102f65.json');
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: 'weddingplanner-89486.appspot.com'
      });
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