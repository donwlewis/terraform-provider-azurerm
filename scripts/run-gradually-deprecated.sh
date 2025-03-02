#!/usr/bin/env bash

function runGraduallyDeprecatedFunctions {
  echo "==> Checking for use of gradually deprecated functions..."

  IFS=$'\n' read -r -d '' -a flist < <(git diff --diff-filter=AMRC master --name-only)

  for f in "${flist[@]}"; do
    # require resources to be imported is now hard-coded on - but only checking for additions
    grep -H -n "features\.ShouldResourcesBeImported" "$f" && {
      echo "The Feature Flag for 'ShouldResourcesBeImported' will be deprecated in the future"
      echo "and shouldn't be used in new resources - please remove new usages of the"
      echo "'ShouldResourcesBeImported' function from these changes - since this is now enabled"
      echo "by default."
      echo ""
      echo "In the future this function will be marked as Deprecated - however it's not for"
      echo "the moment to not conflict with open Pull Requests."
      exit 1
  }

  # using Resource ID Formatters/Parsers
  grep -H -n "d\.SetId(\\*" "$f" && {
      echo "Due to the Azure API returning the Resource ID's inconsistently - Terraform"
      echo "now manages it's own Resource ID's, all new resources should use a generated"
      echo "Resource ID Formatter and Parser."
      echo ""
      echo "A Resource ID Formatter and Parser can be generated by adding a 'resourceids.go'"
      echo "file to the service package (for example"
      echo "./azurerm/internal/services/myservice/resourceids.go) - with the line:"
      echo
      echo "//go:generate go run ../../tools/generator-resource-id/main.go -path=./ -name=Server"
      echo "-id={the value of the Resource ID}"
      echo ""
      echo "At which point running 'make generate' will generate a Resource ID Formatter, Parser"
      echo "and Validator."
      echo ""
      echo "This allows a Resource ID to be defined in-line via:"
      echo "  > subscriptionId := meta.(*clients.Client).Account.SubscriptionId"
      echo "  > id := parse.NewMyResourceId(subscriptionId, resourceGroup, name)"
      echo ""
      echo "This means that the 'SetID' function can change from:"
      echo "  > d.SetId(\"*read.ID\")"
      echo "to:"
      echo "  > d.SetId(id.ID())"
      echo ""
      echo "In addition when parsing the Resource ID during a Read, Update or Delete method"
      echo "the generated Resource ID Parser can be used via:"
      echo "  > id, err := parse.MyResourceID(d.Id())"
      echo "  > if err != nil {"
      echo "  >   return err"
      echo "  > }"
      echo ""
      echo "New Resources should be using Resource ID Formatters/Parsers by default"
      echo "however existing (unmodified) resources can continue to use the Azure ID"
      echo "for the moment - but over time these will be switched across."
      exit 1
  }

done
}

function runDeprecatedFunctions {
  echo "==> Checking for use of deprecated functions..."
  result=$(grep -Ril "d.setid(\"\")" ./azurerm/internal/services/**/data_source_*.go)
  if [ "$result" != "" ];
  then
    echo "Data Sources should return an error when a resource cannot be found rather than"
    echo "setting an empty ID (by calling 'd.SetId("")'."
    echo ""
    echo "Please remove the references to 'd.SetId("") from the Data Sources listed below"
    echo "and raise an error instead:"
    echo ""
    exit 1
  fi
}

function main {
  if [ "$GITHUB_ACTIONS_STAGE" == "UNIT_TESTS" ];
  then
    echo "Skipping - the Gradually Deprecated check is separate in Github Actions"
    echo "so this can be skipped as a part of the build process."
    exit 0
  fi

  runGraduallyDeprecatedFunctions
  runDeprecatedFunctions
}

main
