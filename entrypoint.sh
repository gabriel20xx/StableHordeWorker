#!/bin/bash

echo "Starting entrypoint script"

# Initializing environment values
REPOSITORY="${REPOSITORY:-https://github.com/gabriel20xx/sd-webui-stable-horde-worker.git}"
BRANCH="${BRANCH:-master}"
ENABLED="${ENABLED:-yes}"
ALLOW_IMG2IMG="${ALLOW_IMG2IMG:-yes}"
ALLOW_PAINTING="${ALLOW_PAINTING:-yes}"
ALLOW_UNSAFE_IPADDR="${ALLOW_UNSAFE_IPADDR:-yes}"
ALLOW_POST_PROCESSING="${ALLOW_POST_PROCESSING:-yes}"
RESTORE_SETTINGS="${RESTORE_SETTINGS:-yes}"
SHOW_IMAGE_PREVIEW="${SHOW_IMAGE_PREVIEW:-yes}"
SAVE_IMAGES="${SAVE_IMAGES:-yes}"
SAVE_IMAGES_FOLDER="${SAVE_IMAGES_FOLDER:-none}"
ENDPOINT="${ENDPOINT:-http://stablehorde.net/}"
APIKEY="${APIKEY:-none}"
NAME="${NAME:-none}"
INTERVAL="${INTERVAL:-5}"
MAX_PIXELS="${MAX_PIXELS:-1048576}"
NSFW="${NSFW:-yes}"
HR_UPSCALER="${HR_UPSCALER:-latent}"
HIRES_FIRSTPHASE_RESOLUTION="${HIRES_FIRSTPHASE_RESOLUTION:-1048576}"

# Initialize internal values
MODEL_DIR="/home/user/models/"
SAVE_IMAGES_FOLDER="/home/user/horde/"

# Clone repository
echo "\nRepository: " $REPOSITORY
echo "Branch: " $BRANCH
echo "\nCloning repository.."
cd /home/user/stable-diffusion-webui/extensions
git clone "$REPOSITORY" -b "$BRANCH"
echo "Repository cloned"

# List models
echo "\nThe following files are in the provided folder:"
cd /home/user/stable-diffusion-webui/extensions/sd-webui-stable-horde-worker
ls $MODEL_DIR

# For Horde
# Initialize an empty JSON object for the configuration
config_json="{}"

# Function to add a key-value pair to the config JSON
add_to_config() {
  key="$1"
  value="$2"
  data_type="$3"
  
  if [ -n "$value" ] && [ "$value" != "none" ] && [ "$value" != "" ]; then
    case "$data_type" in
      "string")
        config_json=$(jq --arg key "$key" --arg value "$value" '. + { ($key): $value }' <<< "$config_json")
        ;;
      "int")
        # Convert the string value to an integer
        value_int=$((value))
        config_json=$(jq --arg key "$key" --argjson value "$value_int" '. + { ($key): $value }' <<< "$config_json")
        ;;
      "boolean")
        # Convert the string value to a boolean
        value_bool=$( [ "$value" == "true" ] && echo "true" || echo "false" )
        config_json=$(jq --arg key "$key" --argjson value "$value_bool" '. + { ($key): $value }' <<< "$config_json")
        ;;
      *)
        echo "Invalid data type for $key: $data_type"
        exit 1
        ;;
    esac
  fi
}

# Specify the type for each environment variable and add to the config JSON
# Format: add_to_config "KEY" "VALUE" "TYPE"
add_to_config "enabled" $ENABLED "boolean"
add_to_config "allow_img2img" $ALLOW_IMG2IMG "boolean"
add_to_config "allow_painting" $ALLOW_PAINTING "boolean"
add_to_config "allow_unsafe_ipaddr" $ALLOW_UNSAFE_IPADDR "boolean"
add_to_config "allow_post_processing" $ALLOW_POST_PROCESSING "boolean"
add_to_config "restore_settings" $RESTORE_SETTINGS "boolean"
add_to_config "show_image_preview" $SHOW_IMAGE_PREVIEW "boolean"
add_to_config "save_images" $SAVE_IMAGES "boolean"
add_to_config "save_images_folder" $SAVE_IMAGES_FOLDER "string"
add_to_config "endpoint" $ENDPOINT "string"
add_to_config "apikey" $APIKEY "string"
add_to_config "name" $NAME "string"
add_to_config "interval" $INTERVAL "int"
add_to_config "max_pixels" $MAX_PIXELS "int"
add_to_config "nsfw" $NSFW "boolean"
add_to_config "hr_upscaler" $HR_UPSCALER "string"
add_to_config "hires_firstphase_resolution" $HIRES_FIRSTPHASE_RESOLUTION "int"

# Initialize an empty JSON object for current_models
models_json="{}"

# Loop through the files in $MODEL_DIR
for file in "$MODEL_DIR"/*; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    name="${filename%%.*}" # Extract simplified name without extension

    # Add the JSON entry to the current_models object
    models_json=$(jq --arg name "$name" --arg filename "$filename" \
      '. += { ($name): $filename }' <<< "$models_json")
  fi
done

# Merge the generated current_models object with the existing JSON content
config_json=$(jq --argjson current_models "$models_json" '. + { "current_models": $current_models }' <<< "$config_json")

# Save the config to a file
echo "\nSaving the following config config...:"
echo "$config_json" > config.json
cat config.json
echo "Config saved"

# Run webui.sh
echo "\nEntrypoint script finished, starting webui.sh ..."
cd /home/user/stable-diffusion-webui
./webui.sh --ckpt-dir "$MODEL_DIR" $COMMANDLINE_ARGS