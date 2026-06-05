from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action
from .models import Utilisateur, Antenne, Alarme, Intervention, Interconnexion, Historique, JournalActivite
from .serializers import (
    UtilisateurSerializer, AntenneSerializer, AlarmeSerializer,
    InterventionSerializer, InterconnexionSerializer,
    HistoriqueSerializer, JournalActiviteSerializer
)


# ─── Permissions personnalisées ───────────────────────────────────────────────

class IsAdmin(permissions.BasePermission):
    """Seuls les utilisateurs avec le rôle ADMIN peuvent accéder."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'ADMIN'


class IsAdminOrManager(permissions.BasePermission):
    """Administrateurs et managers peuvent accéder."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ('ADMIN', 'MANAGER')


class IsAuthenticatedReadOnly(permissions.BasePermission):
    """Lecture seule pour les techniciens, CRUD pour admin/manager."""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user.role in ('ADMIN', 'MANAGER')


# ─── Utilitaire journal ───────────────────────────────────────────────────────

def _log(request, action: str, details: str = ''):
    """Crée une entrée de journal d'activité pour l'utilisateur courant."""
    try:
        utilisateur = request.user if request.user.is_authenticated else None
        JournalActivite.objects.create(
            utilisateur=utilisateur,
            action=action,
            details=details,
        )
    except Exception:
        pass  # Ne jamais bloquer une réponse à cause du journal


# ─── ViewSets ─────────────────────────────────────────────────────────────────

class UtilisateurViewSet(viewsets.ModelViewSet):
    queryset = Utilisateur.objects.all().order_by('username')
    serializer_class = UtilisateurSerializer
    permission_classes = [IsAdmin]

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def me(self, request):
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        if response.status_code == status.HTTP_201_CREATED:
            _log(request,
                 'Création utilisateur',
                 f"Utilisateur '{response.data.get('username')}' créé avec le rôle '{response.data.get('role')}'")
        return response

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        _log(request, 'Suppression utilisateur', f"Utilisateur '{instance.username}' supprimé")
        return super().destroy(request, *args, **kwargs)


class AntenneViewSet(viewsets.ModelViewSet):
    queryset = Antenne.objects.all().order_by('nom_site')
    serializer_class = AntenneSerializer
    permission_classes = [IsAuthenticatedReadOnly]

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        if response.status_code == status.HTTP_201_CREATED:
            nom = response.data.get('nom_site', '')
            _log(request, 'Ajout antenne', f"Antenne '{nom}' ajoutée")
            Historique.objects.create(
                antenne_id=response.data['id'],
                description=f"Antenne '{nom}' créée dans le système.",
                type_evenement='AUTRE',
            )
        return response

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        ancien_statut = instance.statut
        response = super().update(request, *args, **kwargs)
        nouveau_statut = response.data.get('statut', '')
        if ancien_statut != nouveau_statut:
            _log(request,
                 'Changement statut antenne',
                 f"Antenne '{instance.nom_site}' : {ancien_statut} → {nouveau_statut}")
            Historique.objects.create(
                antenne=instance,
                description=f"Statut changé de {ancien_statut} à {nouveau_statut}.",
                type_evenement='CHANGEMENT_STATUT',
            )
        return response

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        _log(request, 'Suppression antenne', f"Antenne '{instance.nom_site}' supprimée")
        return super().destroy(request, *args, **kwargs)

    @action(detail=False, methods=['get'], url_path='par-statut')
    def par_statut(self, request):
        """Retourne le nombre d'antennes par statut."""
        data = {}
        for statut, _ in Antenne.STATUT_CHOICES:
            data[statut] = Antenne.objects.filter(statut=statut).count()
        return Response(data)


class AlarmeViewSet(viewsets.ModelViewSet):
    queryset = Alarme.objects.all().order_by('-date_alarme')
    serializer_class = AlarmeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        if response.status_code == status.HTTP_201_CREATED:
            _log(request,
                 'Nouvelle alarme',
                 f"Alarme '{response.data.get('type_alarme')}' créée pour antenne ID {response.data.get('antenne')}")
        return response

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        ancien_statut = instance.statut
        response = super().partial_update(request, *args, **kwargs)
        nouveau_statut = response.data.get('statut', '')
        if ancien_statut != nouveau_statut:
            _log(request,
                 'Mise à jour alarme',
                 f"Alarme ID {instance.id} : {ancien_statut} → {nouveau_statut}")
            if nouveau_statut == 'RESOLUE':
                Historique.objects.create(
                    antenne=instance.antenne,
                    description=f"Alarme '{instance.type_alarme}' résolue.",
                    type_evenement='ALARME',
                )
        return response


class InterventionViewSet(viewsets.ModelViewSet):
    queryset = Intervention.objects.all().order_by('-date_intervention')
    serializer_class = InterventionSerializer
    permission_classes = [IsAuthenticatedReadOnly]

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        if response.status_code == status.HTTP_201_CREATED:
            _log(request,
                 'Nouvelle intervention',
                 f"Intervention planifiée sur antenne ID {response.data.get('antenne')}")
            try:
                antenne_id = response.data.get('antenne')
                Historique.objects.create(
                    antenne_id=antenne_id,
                    description=f"Intervention planifiée : {response.data.get('description', '')}",
                    type_evenement='MAINTENANCE',
                )
            except Exception:
                pass
        return response

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        ancien_statut = instance.statut
        response = super().update(request, *args, **kwargs)
        nouveau_statut = response.data.get('statut', '')
        if ancien_statut != nouveau_statut:
            _log(request,
                 'Mise à jour intervention',
                 f"Intervention ID {instance.id} : {ancien_statut} → {nouveau_statut}")
        return response


class InterconnexionViewSet(viewsets.ModelViewSet):
    queryset = Interconnexion.objects.all()
    serializer_class = InterconnexionSerializer
    permission_classes = [IsAuthenticatedReadOnly]

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        if response.status_code == status.HTTP_201_CREATED:
            _log(request,
                 'Nouvelle interconnexion',
                 f"Liaison créée entre antennes {response.data.get('source')} → {response.data.get('destination')}")
        return response


class HistoriqueViewSet(viewsets.ModelViewSet):
    queryset = Historique.objects.all().order_by('-date_evenement')
    serializer_class = HistoriqueSerializer
    permission_classes = [permissions.IsAuthenticated]

    # Lecture seule pour les techniciens
    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAdminOrManager()]
        return [permissions.IsAuthenticated()]


class JournalActiviteViewSet(viewsets.ModelViewSet):
    queryset = JournalActivite.objects.all().order_by('-date_action')
    serializer_class = JournalActiviteSerializer
    permission_classes = [IsAdmin]
