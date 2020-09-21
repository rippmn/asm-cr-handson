choice=""
while [[ ! $choice || $choice != @(1|2|3) ]];
do
	echo "Select your closest region (Enter 1, 2, or 3)"
	echo "1. US"
	echo "2. Europe"
	echo "3. Asia"
	read choice
	if [[ $choice != @(1|2|3) ]];
	then
		echo "your choice $choice is not valid, please enter a valid selection (1, 2, or 3)";
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
   export GCR_REGION="us";
fi

echo "Using $ZONE_PICK as your zone"