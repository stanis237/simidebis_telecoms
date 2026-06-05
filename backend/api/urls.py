from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UtilisateurViewSet, AntenneViewSet, AlarmeViewSet, InterventionViewSet,
    InterconnexionViewSet, HistoriqueViewSet, JournalActiviteViewSet
)
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

router = DefaultRouter()
router.register(r'utilisateurs', UtilisateurViewSet)
router.register(r'antennes', AntenneViewSet)
router.register(r'alarmes', AlarmeViewSet)
router.register(r'interventions', InterventionViewSet)
router.register(r'interconnexions', InterconnexionViewSet)
router.register(r'historiques', HistoriqueViewSet)
router.register(r'journaux', JournalActiviteViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
