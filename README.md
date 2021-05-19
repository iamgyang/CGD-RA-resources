# CGD-Data-Repository
TEST data repository for CGD RA's

test test test 



votes
I think that Git on Dropbox is great. I use it all the time. I have multiple computers (two at home and one at work) on which I use Dropbox as a central bare repository. Since I don’t want to host it on a public service, and I don’t have access to a server that I can always SSH to, Dropbox takes care of this by syncing in the background (very doing so quickly).

Setup is something like this:

~/project $ git init
~/project $ git add .
~/project $ git commit -m "first commit"
~/project $ cd ~/Dropbox/git

~/Dropbox/git $ git init --bare project.git
~/Dropbox/git $ cd ~/project

~/project $ git remote add origin ~/Dropbox/git/project.git
~/project $ git push -u origin master