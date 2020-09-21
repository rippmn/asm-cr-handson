choice=""
while [[ ! $choice || $choice != @(1|2|3) ]];
do
	echo "Select your closest region"
	echo "1. US"
	echo "2. Europe"
	echo "3. Asia"
	read choice
	if [[ $choice != @(1|2|3) ]];
	then
		echo "your choice $choice is not valid, please enter a valid selection";
	fi
done

if [[ $choice == 3 ]]; then
   export ZONE_PICK="asia-southeast1-b";
   export GCR_REGION="asia";
elif [[ $choice == 2 ]]; then
   export ZONE_PICK="europe-west3-b";
   export GCR_REGION="eu";
else
   export ZONE_PICK="us-central1-f";
fi

echo "Using $ZONE_PICK as your zone"
