/**
 * BettorOdds Firebase Functions
 * Created by Paul Soni on 1/29/25
 * Version: 1.0.0
 */

import {onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Make User Admin Function
export const makeUserAdmin = onCall(async (request) => {
  try {
    // Type check and get email from request
    const email = request.data?.email;
    if (!email || typeof email !== "string") {
      throw new Error("Valid email is required");
    }

    logger.info(`Attempting to make user admin: ${email}`);

    // Get user by email
    const user = await admin.auth().getUserByEmail(email);

    // Update user document
    await admin.firestore().collection("users").doc(user.uid).update({
      adminRole: "admin",
      isEmailVerified: true,
      lastAdminAction: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Set custom claims
    await admin.auth().setCustomUserClaims(user.uid, {
      admin: true,
    });

    logger.info(`Successfully made ${email} an admin`);
    return {success: true, message: `Successfully made ${email} an admin`};
  } catch (error) {
    logger.error("Error making user admin:", error);
    if (error instanceof Error) {
      throw new Error("Failed to make user admin: " + error.message);
    } else {
      throw new Error("Failed to make user admin: Unknown error");
    }
  }
});
