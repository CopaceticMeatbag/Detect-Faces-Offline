$getAwaiterBaseMethod = [System.WindowsRuntimeSystemExtensions].GetMember('GetAwaiter').Where({$PSItem.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'}, 'First')[0]

Function Wait-Async {
        param($AsyncTask, $ResultType)
        $getAwaiterBaseMethod.
            MakeGenericMethod($ResultType).
            Invoke($null, @($AsyncTask)).
            GetResult()
    }
Export-ModuleMember -Function Wait-Async
