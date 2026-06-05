from django.contrib import admin
from .models import Utilisateur, Antenne, Alarme, Intervention


@admin.register(Utilisateur)
class UtilisateurAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'role', 'is_active')
    list_filter = ('role', 'is_active')
    search_fields = ('username', 'email')


@admin.register(Antenne)
class AntenneAdmin(admin.ModelAdmin):
    list_display = ('nom_site', 'latitude', 'longitude', 'frequence', 'statut')
    list_filter = ('statut',)
    search_fields = ('nom_site',)


@admin.register(Alarme)
class AlarmeAdmin(admin.ModelAdmin):
    list_display = ('type_alarme', 'antenne', 'niveau', 'statut', 'date_alarme')
    list_filter = ('niveau', 'statut')
    search_fields = ('type_alarme',)


@admin.register(Intervention)
class InterventionAdmin(admin.ModelAdmin):
    list_display = ('antenne', 'utilisateur', 'date_intervention', 'statut')
    list_filter = ('statut',)
