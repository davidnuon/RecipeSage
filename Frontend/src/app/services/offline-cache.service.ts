import { Injectable } from '@angular/core';

import { PreferencesService, GlobalPreferenceKey } from '@/services/preferences.service';
import { RecipeService } from '@/services/recipe.service';
import { EventService } from '@/services/event.service';

@Injectable({
  providedIn: 'root'
})
export class OfflineCacheService {
  knownRecipeIds = new Set();
  constructor(
    private preferencesService: PreferencesService,
    private recipeService: RecipeService,
    private events: EventService
  ) {
    if (this.preferencesService.preferences[GlobalPreferenceKey.EnableExperimentalOfflineCache]) {
      this.events.subscribe('recipe:created', () => {
        this.updateAllRecipeLists();
      });

      this.events.subscribe('recipe:updated', () => {
        this.updateAllRecipeLists();
      });

      this.events.subscribe('recipe:deleted', () => {
        this.updateAllRecipeLists();
      });
    }
  }

  async fullSync() {
    await this.updateAllRecipeLists();
    await this.updateAllRecipes();
  }

  async syncPause() {
    await new Promise(resolve => setTimeout(resolve, 200));
  }

  async updateAllRecipes() {
    const knownRecipeIds = Array.from(this.knownRecipeIds);
    for (var i = 0; i < knownRecipeIds.length; i++) {
      await this.updateRecipe(knownRecipeIds[i]);

      await this.syncPause();
    }
  }

  async updateRecipe(recipeId) {
    await this.recipeService.fetchById(recipeId);
  }

  async updateAllRecipeLists() {
    const sorts = [
      '-title',
      '-createdAt',
      'createdAt',
      '-updatedAt',
      'updatedAt'
    ];
    for (var i = 0; i < sorts.length; i++) {
      await this.updateRecipeList('main', sorts[i]);
    }
  }

  async updateRecipeList(folder, sortBy) {
    const firstFetch = await this.recipeService.fetch({
      folder,
      sortBy,
      count: 50,
      offset: 0
    });

    firstFetch.data.map(el => this.knownRecipeIds.add(el.id));

    await this.syncPause();

    const pageCount = Math.ceil(firstFetch.totalCount / 50);
    for (var i = 1; i < pageCount; i++) {
      const page = await this.recipeService.fetch({
        folder: 'main',
        sortBy: '-title',
        count: 50,
        offset: i * 50
      });

      page.data.map(el => this.knownRecipeIds.add(el.id));

      await this.syncPause();
    }
  }
}
