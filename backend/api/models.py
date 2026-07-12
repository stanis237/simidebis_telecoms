from django.db import models
from django.contrib.auth.models import AbstractUser

class Utilisateur(AbstractUser):
    ROLE_CHOICES = (
        ('ADMIN', 'Administrateur'),
        ('MANAGER', 'Manager'),
        ('TECHNICIEN', 'Technicien'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='TECHNICIEN')

    def __str__(self):
        return f"{self.username} - {self.get_role_display()}"


class Antenne(models.Model):
    nom_site = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=10, decimal_places=6)
    longitude = models.DecimalField(max_digits=10, decimal_places=6)
    altitude = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    frequence = models.CharField(max_length=100, null=True, blank=True)

    # Paramètres techniques ajoutés
    azimuth = models.FloatField(null=True, blank=True)
    tilt = models.FloatField(null=True, blank=True)
    puissance_tx = models.FloatField(default=20.0)
    polarisation = models.CharField(max_length=50, default='Verticale')
    downtilt = models.FloatField(default=0.0)

    STATUT_CHOICES = (
        ('ACTIF', 'Actif'),
        ('EN_ATTENTE', 'En attente'),
        ('ALARME', 'Alarme'),
        ('HORS_LIGNE', 'Hors ligne'),
    )
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='ACTIF')

    def __str__(self):
        return self.nom_site


class Alarme(models.Model):
    antenne = models.ForeignKey(Antenne, on_delete=models.CASCADE, related_name='alarmes')
    type_alarme = models.CharField(max_length=255)
    date_alarme = models.DateTimeField(auto_now_add=True)
    
    NIVEAU_CHOICES = (
        ('MINEURE', 'Mineure'),
        ('MAJEURE', 'Majeure'),
        ('CRITIQUE', 'Critique'),
    )
    niveau = models.CharField(max_length=20, choices=NIVEAU_CHOICES, default='MINEURE')
    
    STATUT_CHOICES = (
        ('NON_RESOLUE', 'Non résolue'),
        ('EN_COURS', 'En cours'),
        ('RESOLUE', 'Résolue'),
    )
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='NON_RESOLUE')

    def __str__(self):
        return f"{self.type_alarme} - {self.antenne.nom_site}"


class Intervention(models.Model):
    utilisateur = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name='interventions')
    antenne = models.ForeignKey(Antenne, on_delete=models.CASCADE, related_name='interventions')
    date_intervention = models.DateTimeField()
    description = models.TextField()
    
    STATUT_CHOICES = (
        ('PLANIFIEE', 'Planifiée'),
        ('EN_COURS', 'En cours'),
        ('TERMINEE', 'Terminée'),
        ('ANNULEE', 'Annulée'),
    )
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='PLANIFIEE')

    def __str__(self):
        return f"Intervention sur {self.antenne.nom_site} par {self.utilisateur.username}"


class Interconnexion(models.Model):
    source = models.ForeignKey(Antenne, on_delete=models.CASCADE, related_name='connexions_sortantes')
    destination = models.ForeignKey(Antenne, on_delete=models.CASCADE, related_name='connexions_entrantes')
    type_liaison = models.CharField(max_length=100)
    bande_passante = models.CharField(max_length=100)
    
    STATUT_CHOICES = (
        ('ACTIF', 'Actif'),
        ('INACTIF', 'Inactif'),
        ('EN_MAINTENANCE', 'En maintenance'),
    )
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='ACTIF')

    def __str__(self):
        return f"{self.source.nom_site} -> {self.destination.nom_site}"


class Historique(models.Model):
    antenne = models.ForeignKey(Antenne, on_delete=models.CASCADE, related_name='historiques')
    date_evenement = models.DateTimeField(auto_now_add=True)
    description = models.TextField()
    
    TYPE_EVENEMENT_CHOICES = (
        ('CHANGEMENT_STATUT', 'Changement de statut'),
        ('ALARME', 'Alarme'),
        ('MAINTENANCE', 'Maintenance'),
        ('AUTRE', 'Autre'),
    )
    type_evenement = models.CharField(max_length=50, choices=TYPE_EVENEMENT_CHOICES, default='AUTRE')

    def __str__(self):
        return f"{self.antenne.nom_site} - {self.date_evenement.strftime('%Y-%m-%d %H:%M')}"


class JournalActivite(models.Model):
    utilisateur = models.ForeignKey(Utilisateur, on_delete=models.SET_NULL, null=True, blank=True, related_name='journaux')
    action = models.CharField(max_length=255)
    details = models.TextField(null=True, blank=True)
    date_action = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.utilisateur.username if self.utilisateur else 'Système'} - {self.action}"
