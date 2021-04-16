package storage

import (
	"fmt"
	"log"
	"strings"

	"github.com/terraform-providers/terraform-provider-azurerm/azurerm/helpers/azure"
	"github.com/terraform-providers/terraform-provider-azurerm/azurerm/internal/clients"
	"github.com/terraform-providers/terraform-provider-azurerm/azurerm/internal/tf/pluginsdk"
	"github.com/terraform-providers/terraform-provider-azurerm/azurerm/internal/tf/validation"
	"github.com/tombuildsstuff/giovanni/storage/2019-12-12/file/shares"
)

// the schema schema was used for both V0 and V1
func resourceStorageShareStateResourceV0V1() *pluginsdk.Resource {
	return &pluginsdk.Resource{
		Schema: map[string]*pluginsdk.Schema{
			"name": {
				Type:     pluginsdk.TypeString,
				Required: true,
				ForceNew: true,
			},
			"resource_group_name": azure.SchemaResourceGroupName(),
			"storage_account_name": {
				Type:     pluginsdk.TypeString,
				Required: true,
				ForceNew: true,
			},
			"quota": {
				Type:         pluginsdk.TypeInt,
				Optional:     true,
				Default:      5120,
				ValidateFunc: validation.IntBetween(1, 5120),
			},
			"url": {
				Type:     pluginsdk.TypeString,
				Computed: true,
			},
		},
	}
}

func ResourceStorageShareStateUpgradeV0ToV1(rawState map[string]interface{}, _ interface{}) (map[string]interface{}, error) {
	shareName := rawState["name"].(string)
	resourceGroup := rawState["resource_group_name"].(string)
	accountName := rawState["storage_account_name"].(string)

	id := rawState["id"].(string)
	newResourceID := fmt.Sprintf("%s/%s/%s", shareName, resourceGroup, accountName)
	log.Printf("[DEBUG] Updating ID from %q to %q", id, newResourceID)

	rawState["id"] = newResourceID
	return rawState, nil
}

func ResourceStorageShareStateUpgradeV1ToV2(rawState map[string]interface{}, meta interface{}) (map[string]interface{}, error) {
	id := rawState["id"].(string)

	// name/resourceGroup/accountName
	parsedId := strings.Split(id, "/")
	if len(parsedId) != 3 {
		return rawState, fmt.Errorf("Expected 3 segments in the ID but got %d", len(parsedId))
	}

	shareName := parsedId[0]
	accountName := parsedId[2]

	environment := meta.(*clients.Client).Account.Environment
	client := shares.NewWithEnvironment(environment)

	newResourceId := client.GetResourceID(accountName, shareName)
	log.Printf("[DEBUG] Updating Resource ID from %q to %q", id, newResourceId)

	rawState["id"] = newResourceId

	return rawState, nil
}
