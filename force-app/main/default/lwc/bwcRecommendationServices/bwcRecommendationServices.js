import getRecommendationsCont  from '@salesforce/apexContinuation/BWC_RecommendationsController.getRecommendationsCont';

export const getRecommendations = async (interactionId) => {

    const responseJson = await getRecommendationsCont({interactionId});

    return JSON.parse(responseJson);

}