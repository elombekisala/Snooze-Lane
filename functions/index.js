const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

admin.initializeApp();

const accountSid = functions.config().twilio.sid;
const authToken = functions.config().twilio.token;
const twilioPhoneNumber = functions.config().twilio.phone_number;

const client = new twilio(accountSid, authToken);

let callInProgress = false;

exports.makeCallOnTrigger = functions.https.onCall(async (data, context) => {
    // Check if request is made by an authenticated user
    if (!context.auth) {
        console.error("Unauthenticated request");
        throw new functions.https.HttpsError("unauthenticated", "The function must be called while authenticated.");
    }

    // Debounce check to prevent multiple simultaneous calls
    if (callInProgress) {
        console.warn("Call already in progress");
        throw new functions.https.HttpsError("resource-exhausted", "Call already in progress.");
    }

    callInProgress = true;
    
    try {
        console.log("Entering try block, preparing to make call");

        // Retrieve the phone number of the authenticated user
        const userRecord = await admin.auth().getUser(context.auth.uid);
        const phoneNumber = userRecord.phoneNumber;

        // Ensure the user's phone number is available
        if (!phoneNumber) {
            console.error("No phone number available for the user:", context.auth.uid);
            throw new functions.https.HttpsError("not-found", "No phone number available for the user.");
        }

        // Placing a call with Twilio
        const call = await client.calls.create({
            url: "http://twimlets.com/message?Message%5B0%5D=This%20is%20Snooze%20Lane.%20You%20are%20arriving%20at%20your%20stop",
            to: phoneNumber,
            from: twilioPhoneNumber
        });

        console.log(`Call initiated with SID: ${call.sid} to ${phoneNumber}`);

        return { result: `Call initiated to ${phoneNumber}` };

    } catch (error) {
        console.error("Error during Twilio call:", error);
        
        // Check if the error is a known Firebase HttpsError, otherwise throw a generic internal error
        if (error instanceof functions.https.HttpsError) {
            throw error;
        } else {
            throw new functions.https.HttpsError("internal", "Failed to initiate call.", error.message);
        }

    } finally {
        console.log("Resetting callInProgress to false");
        callInProgress = false;

        // Optional: Timeout-based reset as a safety measure
        setTimeout(() => {
            if (callInProgress) {
                console.warn("Forcing reset of callInProgress due to timeout");
                callInProgress = false;
            }
        }, 5000);  // Adjust the timeout duration as needed
    }
});
