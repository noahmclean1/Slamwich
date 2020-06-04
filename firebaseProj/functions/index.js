// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();


// Take the text parameter passed to this HTTP endpoint and insert it into the
// Realtime Database under the path /messages/:pushId/original
exports.addMessage = functions.https.onRequest(async (req, res) => {
  // Grab the text parameter.
  const original = req.query.text;
  // Push the new message into the Realtime Database using the Firebase Admin SDK.
  const snapshot = await admin.database().ref('/messages').push({original: original});
  // Redirect with 303 SEE OTHER to the URL of the pushed object in the Firebase console.
  //res.send(original.toString());
  res.send(snapshot.ref.toString());
});

// Enqueue user for an online match
exports.joinQueue = functions.https.onRequest(async (req, res) => {
	const username = req.query.username;

	// Add users to the queue
	const snapshot = await admin.database().ref('/queuedUsers').push({username: username});

	res.send(snapshot.ref.toString());
});

// Attempt to add 2 users to a game
// Triggered when a user is added to the queue
exports.tryToMakeGame = functions.https.onRequest(async (req, res) => {
	await admin.database().ref('/queuedUsers').orderByKey().limitToLast(2).once('value', snap => {
		//console.log(snap.toString())
		res.send(snap.val());
	});
	
});


function function_name(argument) {
	// body...
}