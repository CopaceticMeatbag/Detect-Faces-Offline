# Detect-Faces-Offline
Uses UWP Windows Face Analysis to check an image for face(s). I used this for processing large batches of files including uploads, so I nested it in a threaded job that processes up to 6 concurrent files. Some functions are split off intoa module file as there was originally a ton more that I've pared back to basics just for the face detection.

It assumes scripts live in c:\scripts\ (yes I know what relative paths are, eat my shorts xD)
