package org.springframework.samples.petclinic.visits.model;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;


@Getter
@Setter
@ConfigurationProperties(prefix = "azure.cosmosdb")
class CosmosDbProperties {

    private String uri;

    private String key;

    private String secondaryKey;

    private String database;

    private boolean populateQueryMetrics;
}
