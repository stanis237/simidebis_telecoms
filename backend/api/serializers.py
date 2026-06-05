from rest_framework import serializers
from .models import Utilisateur, Antenne, Alarme, Intervention, Interconnexion, Historique, JournalActivite

class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'role', 'password')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = Utilisateur.objects.create_user(**validated_data)
        return user

class AlarmeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alarme
        fields = '__all__'

class InterventionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Intervention
        fields = '__all__'

class AntenneSerializer(serializers.ModelSerializer):
    alarmes = AlarmeSerializer(many=True, read_only=True)
    
    class Meta:
        model = Antenne
        fields = '__all__'

class InterconnexionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Interconnexion
        fields = '__all__'

class HistoriqueSerializer(serializers.ModelSerializer):
    class Meta:
        model = Historique
        fields = '__all__'

class JournalActiviteSerializer(serializers.ModelSerializer):
    class Meta:
        model = JournalActivite
        fields = '__all__'
