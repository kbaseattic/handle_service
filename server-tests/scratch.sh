export KB_DEPLOYMENT_CONFIG=$KB_TOP/modules/data_store/deploy.cfg 

echo "can it be found"
perl -e 'use Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl;'

echo "can it be instanciated"
perl -e 'use Data::Dumper; use Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl; $dsi=Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl->new();'

echo "does new_handle() work"
perl -e 'use Data::Dumper; use Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl; $dsi=Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl->new(); print Dumper $dsi->new_handle("GenomeAnnotation")'


echo "does localize() work"
perl -e 'use Data::Dumper; use Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl; $dsi=Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl->new(); print Dumper $dsi->localize("Invocation", $dsi->new_handle());'

# echo "does initialize_handle() work"
perl -e 'use Data::Dumper; use Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl; $dsi=Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl->new(); print Dumper $dsi->initialize_handle($dsi->new_handle());'

